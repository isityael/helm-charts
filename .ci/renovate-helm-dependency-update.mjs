#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    encoding: "utf8",
    stdio: "inherit",
    ...options,
  });
}

function dockerHostRules() {
  const raw = process.env.RENOVATE_HOST_RULES;
  if (!raw) {
    return [];
  }
  const rules = JSON.parse(raw);
  if (!Array.isArray(rules)) {
    throw new Error("RENOVATE_HOST_RULES must be a JSON array");
  }
  return rules.filter(
    (rule) =>
      rule?.hostType === "docker" &&
      rule.matchHost &&
      rule.username &&
      rule.password,
  );
}

function authenticateRegistries() {
  const authenticated = new Set();
  for (const rule of dockerHostRules()) {
    if (authenticated.has(rule.matchHost)) {
      continue;
    }
    run(
      "helm",
      [
        "registry",
        "login",
        "--username",
        rule.username,
        "--password-stdin",
        rule.matchHost,
      ],
      {
        input: `${rule.password}\n`,
        stdio: ["pipe", "inherit", "inherit"],
      },
    );
    authenticated.add(rule.matchHost);
  }
}

// CSI-S3's schema and image-updater contract require a v-prefixed owned tag,
// while Helm appVersion records the same release without the prefix.
function syncCsiMetadata(chartDirectory) {
  if (chartDirectory !== "charts/csi-s3") return;
  const values = readFileSync(join(chartDirectory, "values.yaml"), "utf8");
  const maintained = values.match(/^maintainedImage:\n((?:[ \t].*\n?)*)/m)?.[1];
  if (!maintained?.match(/^  repository: ghcr\.io\/isityael\/csi-s3-driver\s*$/m)) {
    throw new Error("CSI-S3 maintained image repository contract changed");
  }
  const tag = maintained.match(/^  tag: ["']?(v\d+\.\d+\.\d+-yael\.[1-9]\d*)["']?\s*$/m)?.[1];
  if (!tag) throw new Error("CSI-S3 maintained image must use a v-prefixed fork release");
  const chartPath = join(chartDirectory, "Chart.yaml");
  const chart = readFileSync(chartPath, "utf8");
  if (!/^appVersion:.*$/m.test(chart)) throw new Error("CSI-S3 appVersion is missing");
  writeFileSync(chartPath, chart.replace(/^appVersion:.*$/m, `appVersion: "${tag.slice(1)}"`));
  const readmePath = join(chartDirectory, "README.md");
  const readme = readFileSync(readmePath, "utf8");
  writeFileSync(readmePath, readme.replace(/^maintainedImage:\n((?:[ \t].*\n?)*)/gm, (block) => {
    const previousTag = block.match(/^  tag: (v\d+\.\d+\.\d+-yael\.\d+)$/m)?.[1];
    if (!previousTag || previousTag === tag) return block;
    // A digest belongs to one immutable release; don't retain the old release's
    // pin when advancing this documentation example to a new tag.
    return block.replace(/^  tag: .*$/m, `  tag: ${tag}`)
      .replace(/^  digest: .*$/m, '  digest: ""');
  }));
}

function main() {
  const chartDirectories = process.argv.slice(2);
  if (chartDirectories.length === 0) {
    throw new Error("at least one Helm chart directory is required");
  }
  authenticateRegistries();
  for (const chartDirectory of chartDirectories) {
    run("helm", ["dependency", "update", chartDirectory]);
    syncCsiMetadata(chartDirectory);
  }
}

try {
  main();
} catch (error) {
  console.error(`renovate helm dependency update: ${error.message}`);
  process.exitCode = 1;
}
