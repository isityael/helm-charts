#!/usr/bin/env node

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const command = join(repoRoot, ".ci/renovate-helm-dependency-update.mjs");

test("authenticates OCI registries before refreshing dependencies without exposing credentials", () => {
  const fixture = mkdtempSync(join(tmpdir(), "renovate-helm-auth-"));
  const fakeBin = join(fixture, "bin");
  const callLog = join(fixture, "helm-calls");
  mkdirSync(fakeBin);
  writeFileSync(
    join(fakeBin, "helm"),
    `#!/bin/sh
set -eu
printf 'args=%s\\n' "$*" >> "$HELM_CALL_LOG"
if [ "$1" = "registry" ]; then
  IFS= read -r input
  printf 'stdin=%s\\n' "$input" >> "$HELM_CALL_LOG"
fi
`,
  );
  chmodSync(join(fakeBin, "helm"), 0o755);

  const credential = "fixture-only";
  const result = spawnSync(process.execPath, [command, "charts/example"], {
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${fakeBin}:${process.env.PATH}`,
      HELM_CALL_LOG: callLog,
      RENOVATE_HOST_RULES: JSON.stringify([
        {
          hostType: "docker",
          matchHost: "dhi.io",
          username: "fixture-user",
          password: credential,
        },
        {
          hostType: "github",
          matchHost: "github.com",
          token: "ignored-fixture",
        },
      ]),
    },
  });

  assert.equal(result.status, 0, `stdout:\n${result.stdout}\nstderr:\n${result.stderr}`);
  assert.equal(
    readFileSync(callLog, "utf8"),
    [
      "args=registry login --username fixture-user --password-stdin dhi.io",
      `stdin=${credential}`,
      "args=dependency update charts/example",
      "",
    ].join("\n"),
  );
  assert.doesNotMatch(`${result.stdout}\n${result.stderr}`, new RegExp(credential));
});


test("keeps CSI-S3 appVersion and examples aligned with the maintained v-prefixed image", () => {
  const fixture = mkdtempSync(join(tmpdir(), "renovate-csi-metadata-"));
  const chart = join(fixture, "charts/csi-s3");
  const fakeBin = join(fixture, "bin");
  mkdirSync(chart, { recursive: true });
  mkdirSync(fakeBin);
  writeFileSync(join(fakeBin, "helm"), "#!/bin/sh\nexit 0\n");
  chmodSync(join(fakeBin, "helm"), 0o755);
  writeFileSync(join(chart, "Chart.yaml"), 'name: csi-s3\nversion: 0.1.20\nappVersion: "0.43.9-yael.2"\n');
  writeFileSync(join(chart, "values.yaml"), 'maintainedImage:\n  repository: ghcr.io/isityael/csi-s3-driver\n  tag: v0.43.9-yael.3\n  digest: ""\n');
  writeFileSync(join(chart, "README.md"), 'Example:\n  tag: v0.43.9-yael.2\n');
  const result = spawnSync(process.execPath, [command, "charts/csi-s3"], {
    cwd: fixture,
    encoding: "utf8",
    env: { ...process.env, PATH: `${fakeBin}:${process.env.PATH}`, RENOVATE_HOST_RULES: "[]" },
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(readFileSync(join(chart, "Chart.yaml"), "utf8"), 'name: csi-s3\nversion: 0.1.20\nappVersion: "0.43.9-yael.3"\n');
  assert.equal(readFileSync(join(chart, "README.md"), "utf8"), 'Example:\n  tag: v0.43.9-yael.3\n');

  // Reject the exact malformed tag that previously passed Renovate lookup.
  writeFileSync(join(chart, "values.yaml"), 'maintainedImage:\n  repository: ghcr.io/isityael/csi-s3-driver\n  tag: 0.43.9-yael.4\n');
  const invalid = spawnSync(process.execPath, [command, "charts/csi-s3"], {
    cwd: fixture,
    encoding: "utf8",
    env: { ...process.env, PATH: `${fakeBin}:${process.env.PATH}`, RENOVATE_HOST_RULES: "[]" },
  });
  assert.equal(invalid.status, 1);
  assert.match(invalid.stderr, /v-prefixed fork release/);
  assert.match(readFileSync(join(chart, "Chart.yaml"), "utf8"), /appVersion: "0\.43\.9-yael\.3"/);
});
