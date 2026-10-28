import os, pathlib, subprocess, tempfile, unittest
chart=str(pathlib.Path(__file__).resolve().parents[1])
rendered=subprocess.check_output(['helm','template','cache',chart,'--namespace','default','-f',chart+'/ci/test-values.yaml','--show-only','templates/prestop-configmap.yaml'],text=True)
block=rendered.split('  ready.sh: |\n',1)[1].split('  prestop.sh:',1)[0]
script='\n'.join(line[4:] for line in block.splitlines())+'\n'
class Readiness(unittest.TestCase):
 def check(self, scenario):
  with tempfile.TemporaryDirectory() as directory:
   p=pathlib.Path(directory);(p/'ready.sh').write_text(script)
   (p/'valkey-cli').write_text('''#!/bin/sh
case "$*" in
 *CKQUORUM*) [ "$SCENARIO" = quorum ] && echo NOQUORUM || echo OK; exit 0;;
 *'-h primary'*) echo master_repl_offset:100; exit 0;;
esac
case "$SCENARIO" in
 primary) printf 'role:master\\nconnected_slaves:0\\nmaster_failover_state:no-failover\\n';;
 down) printf 'role:slave\\nmaster_link_status:down\\nmaster_sync_in_progress:0\\n';;
 *) printf 'role:slave\\nmaster_link_status:up\\nmaster_sync_in_progress:0\\nmaster_host:primary\\nmaster_port:6379\\n';
    [ "$SCENARIO" = stale ] && echo slave_repl_offset:99 || echo slave_repl_offset:100;;
esac
''');(p/'valkey-cli').chmod(0o755)
   return subprocess.run(['sh',str(p/'ready.sh')],env={**os.environ,'PATH':str(p)+':'+os.environ['PATH'],'SCENARIO':scenario},capture_output=True).returncode
 def test_synchronized_replica(self): self.assertEqual(self.check('good'),0)
 def test_stale_replica(self): self.assertNotEqual(self.check('stale'),0)
 def test_disconnected_replica(self): self.assertNotEqual(self.check('down'),0)
 def test_primary_without_replica(self): self.assertNotEqual(self.check('primary'),0)
 def test_quorum_missing(self): self.assertNotEqual(self.check('quorum'),0)
class PrimaryRouting(unittest.TestCase):
 def check(self, scenario):
  output=subprocess.check_output(['helm','template','cache',chart,'--namespace','default','-f',chart+'/ci/test-values.yaml','--set','replicaCount=2','--set','sentinel.witness.enabled=true','--set','sentinel.allowUnreplicatedWrites=true','--show-only','templates/prestop-configmap.yaml'],text=True)
  block=output.split('  primary-check.sh: |\n',1)[1].split('  ready.sh:',1)[0]
  source='\n'.join(line[4:] for line in block.splitlines())+'\n'
  with tempfile.TemporaryDirectory() as directory:
   p=pathlib.Path(directory);(p/'check.sh').write_text(source)
   (p/'nc').write_text("""#!/bin/sh
read query
case "$query" in
 SENTINEL*)
   [ "$SCENARIO" = unavailable ] && exit 1
   if [ "$SCENARIO" = minority ] && [ "$3" != cache-valkey-ha-0.cache-valkey-ha-headless.default.svc.cluster.local ]; then exit 1; fi
   master=cache-valkey-ha-0.cache-valkey-ha-headless.default.svc.cluster.local
   [ "$SCENARIO" = stale ] && master=another-primary
   printf '*2\\r\\n$80\\r\\n%s\\r\\n$4\\r\\n6379\\r\\n' "$master";;
 *)
   [ "$SCENARIO" = replica ] && role=slave || role=master
   printf 'role:%s\\r\\nconnected_slaves:0\\r\\nmaster_failover_state:no-failover\\r\\n' "$role";;
esac
""");(p/'nc').chmod(0o755)
   return subprocess.run(['sh',str(p/'check.sh'),'unused','unused','10.0.0.1','6379'],env={**os.environ,'PATH':str(p)+':'+os.environ['PATH'],'SCENARIO':scenario,'HAPROXY_SERVER_NAME':'cache-valkey-ha-0'},capture_output=True).returncode
 def test_primary_with_replica_offline(self): self.assertEqual(self.check('good'),0)
 def test_minority_rejected(self): self.assertNotEqual(self.check('minority'),0)
 def test_stale_primary_rejected(self): self.assertNotEqual(self.check('stale'),0)
 def test_replica_rejected(self): self.assertNotEqual(self.check('replica'),0)
 def test_unavailable_sentinels_rejected(self): self.assertNotEqual(self.check('unavailable'),0)
unittest.main()
