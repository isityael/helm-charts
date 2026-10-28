import os, pathlib, subprocess, tempfile, unittest
chart=str(pathlib.Path(__file__).resolve().parents[1])
rendered=subprocess.check_output(['helm','template','cache',chart,'-f',chart+'/ci/test-values.yaml','--show-only','templates/prestop-configmap.yaml'],text=True)
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
unittest.main()
