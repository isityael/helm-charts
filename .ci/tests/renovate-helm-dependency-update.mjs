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
