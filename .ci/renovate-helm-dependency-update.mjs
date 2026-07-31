#!/usr/bin/env node

import { execFileSync } from "node:child_process";

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

function main() {
  const chartDirectories = process.argv.slice(2);
  if (chartDirectories.length === 0) {
    throw new Error("at least one Helm chart directory is required");
  }
  authenticateRegistries();
  for (const chartDirectory of chartDirectories) {
    run("helm", ["dependency", "update", chartDirectory]);
  }
}

try {
  main();
} catch (error) {
  console.error(`renovate helm dependency update: ${error.message}`);
  process.exitCode = 1;
}
