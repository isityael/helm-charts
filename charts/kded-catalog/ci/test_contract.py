"""Offline Helm contract checks; render-only fixture images never reach a cluster."""
from pathlib import Path
import subprocess
import unittest
import yaml

CHART = Path(__file__).resolve().parents[1]
# Explicitly inert fixture used only as Helm input, never installation values.
FIXTURE = 'example.invalid/kded-catalog@sha256:' + '0' * 64


def render(*overrides):
    command = ['helm', 'template', 'kded-catalog', str(CHART), '-n', 'apps']
    for override in overrides:
        command.extend(['--set', override])
    return subprocess.run(command, text=True, capture_output=True)


class Contract(unittest.TestCase):
    def test_disabled_default_has_no_resources(self):
        result = render()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(list(yaml.safe_load_all(result.stdout)))

    def test_enabled_requires_immutable_image(self):
        result = render('enabled=true', 'image.spec=example.invalid/catalog:latest')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('pinned to a verified sha256', result.stderr)

    def test_source_wildcards_are_rejected(self):
        result = render('networkPolicy.sourceHosts[0]=*.example.org')
        self.assertNotEqual(result.returncode, 0)

    def test_private_runtime_contract(self):
        result = render('enabled=true', 'image.spec=' + FIXTURE, 'tailscale.enabled=true')
        self.assertEqual(result.returncode, 0, result.stderr)
        resources = {item['kind']: item for item in yaml.safe_load_all(result.stdout)}
        pod = resources['Deployment']['spec']['template']['spec']
        self.assertFalse(pod['automountServiceAccountToken'])
        self.assertEqual(pod['securityContext']['runAsUser'], 65532)
        self.assertEqual(pod['volumes'][1]['secret']['items'], [{'key': 'ca.crt', 'path': 'ca.crt'}])
        self.assertTrue(pod['containers'][0]['securityContext']['readOnlyRootFilesystem'])
        env = {x['name']: x['value'] for x in pod['containers'][0]['env']}
        self.assertEqual(env['PGSSLMODE'], 'verify-full')
        self.assertEqual(resources['Ingress']['spec']['ingressClassName'], 'tailscale')
        cnp = resources['CiliumNetworkPolicy']['spec']
        self.assertEqual(cnp['egress'][2]['toFQDNs'], [{'matchName': 'macked.app'}, {'matchName': 'appstorrent.ru'}])
        self.assertEqual(cnp['egress'][2]['toPorts'][0]['ports'], [{'port': '443', 'protocol': 'TCP'}])
        self.assertNotIn('PersistentVolumeClaim', resources)
        self.assertNotIn('Secret', resources)
        self.assertNotIn('clusterIP', resources['Service']['spec'])


if __name__ == '__main__':
    unittest.main()
