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

test("the current CSI-S3 registry is covered by Renovate metadata synchronization", () => {
  const schema = JSON.parse(readFileSync(join(repoRoot, "charts/csi-s3/values.schema.json"), "utf8"));
  const repository = schema.properties.maintainedImage.properties.repository.const;
  const config = JSON.parse(readFileSync(join(repoRoot, "renovate.json"), "utf8"));
  const rule = config.packageRules.find((rule) =>
    rule.matchManagers?.includes("helm-values") &&
    rule.matchFileNames?.includes("charts/csi-s3/values.yaml") &&
    rule.matchPackageNames?.includes(repository) &&
    rule.postUpgradeTasks?.commands?.includes("node .ci/renovate-helm-dependency-update.mjs charts/csi-s3"));
  assert.ok(rule, "image updates must synchronize metadata for the schema's current registry");
  assert.ok(rule.postUpgradeTasks.fileFilters.includes("charts/csi-s3/**"),
    "Renovate must retain the synchronized Chart.yaml and README.md");
});

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
  writeFileSync(join(chart, "values.schema.json"), readFileSync(join(repoRoot, "charts/csi-s3/values.schema.json")));
  writeFileSync(join(chart, "Chart.yaml"), 'name: csi-s3\nversion: 0.1.20\nappVersion: "0.43.9-yael.2"\n');
  writeFileSync(join(chart, "values.yaml"), 'maintainedImage:\n  repository: git.m0sh1.cc/isityael/csi-s3-driver\n  tag: v0.43.9-yael.3\n  digest: ""\n');
  writeFileSync(join(chart, "README.md"), 'Example:\nmaintainedImage:\n  tag: v0.43.9-yael.2\n  digest: sha256:old-release\n');
  const result = spawnSync(process.execPath, [command, "charts/csi-s3"], {
    cwd: fixture,
    encoding: "utf8",
    env: { ...process.env, PATH: `${fakeBin}:${process.env.PATH}`, RENOVATE_HOST_RULES: "[]" },
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(readFileSync(join(chart, "Chart.yaml"), "utf8"), 'name: csi-s3\nversion: 0.1.20\nappVersion: "0.43.9-yael.3"\n');
  assert.equal(readFileSync(join(chart, "README.md"), "utf8"), 'Example:\nmaintainedImage:\n  tag: v0.43.9-yael.3\n  digest: ""\n');

  // Reject the obsolete registry using the production schema as the authority.
  const values = readFileSync(join(chart, "values.yaml"), "utf8");
  writeFileSync(join(chart, "values.yaml"), values.replace("git.m0sh1.cc/isityael", "ghcr.io/isityael"));
  const obsolete = spawnSync(process.execPath, [command, "charts/csi-s3"], {
    cwd: fixture,
    encoding: "utf8",
    env: { ...process.env, PATH: `${fakeBin}:${process.env.PATH}`, RENOVATE_HOST_RULES: "[]" },
  });
  assert.equal(obsolete.status, 1);
  assert.match(obsolete.stderr, /repository contract changed/);

  // Reject the exact malformed tag that previously passed Renovate lookup.
  writeFileSync(join(chart, "values.yaml"), 'maintainedImage:\n  repository: git.m0sh1.cc/isityael/csi-s3-driver\n  tag: 0.43.9-yael.4\n');
  const invalid = spawnSync(process.execPath, [command, "charts/csi-s3"], {
    cwd: fixture,
    encoding: "utf8",
    env: { ...process.env, PATH: `${fakeBin}:${process.env.PATH}`, RENOVATE_HOST_RULES: "[]" },
  });
  assert.equal(invalid.status, 1);
  assert.match(invalid.stderr, /v-prefixed fork release/);
  assert.match(readFileSync(join(chart, "Chart.yaml"), "utf8"), /appVersion: "0\.43\.9-yael\.3"/);
});


test("uses mounted registry authentication when Renovate removes secret environment variables", () => {
  const fixture = mkdtempSync(join(tmpdir(), "renovate-helm-mounted-auth-"));
  const fakeBin = join(fixture, "bin");
  const dockerConfig = join(fixture, "docker.json");
  const registryConfig = join(fixture, "helm/config.json");
  const callLog = join(fixture, "calls");
  mkdirSync(fakeBin);
  writeFileSync(dockerConfig, JSON.stringify({ auths: { "dhi.io": { auth: "fixture-only" } } }));
  writeFileSync(join(fakeBin, "helm"), '#!/bin/sh\nprintf "%s\\n" "$*" > "$HELM_CALL_LOG"\n');
  chmodSync(join(fakeBin, "helm"), 0o755);
  const result = spawnSync(process.execPath, [command, "charts/example"], {
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${fakeBin}:${process.env.PATH}`,
      HELM_CALL_LOG: callLog,
      RENOVATE_HOST_RULES: "[]",
      RENOVATE_DOCKER_CONFIG_FILE: dockerConfig,
      RENOVATE_HELM_REGISTRY_CONFIG_FILE: registryConfig,
    },
  });
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(readFileSync(registryConfig)), { auths: { "dhi.io": { auth: "fixture-only" } } });
  assert.equal(readFileSync(callLog, "utf8").trim(), `dependency update --registry-config ${registryConfig} charts/example`);
  assert.doesNotMatch(`${result.stdout}\n${result.stderr}`, /fixture-only/);
});
