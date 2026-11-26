import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const repo = path.resolve(import.meta.dirname, "..");
const nix = fs.readFileSync(path.join(repo, "modules/home/ai.nix"), "utf-8");

const start = nix.indexOf("const READ_ONLY_CMDS = [");
const end = nix.indexOf("const CODE_PATH =", start);
assert.ok(start !== -1 && end !== -1, "could not locate bashIsReadOnly block in ai.nix");

const js = nix
  .slice(start, end)
  .replace(/function firstSubcommand\(parts: string\[\]\): string \| undefined/g, "function firstSubcommand(parts)")
  .replace(/function segmentIsReadOnly\(seg: string\): boolean/g, "function segmentIsReadOnly(seg)")
  .replace(/function bashIsReadOnly\(command: string\): boolean/g, "function bashIsReadOnly(command)");

const ctx = {};
vm.runInNewContext(`${js}\nthis.bashIsReadOnly = bashIsReadOnly;`, ctx);
const { bashIsReadOnly } = ctx;

// Allowed read-only commands
for (const cmd of [
  "ls -la",
  "git status",
  "git -C /tmp/repo diff --stat",
  "git grep -c foo",
  "git stash list",
  "git branch",
  "nix eval .#nixosConfigurations.desktop.config.networking.hostName",
  "rg foo modules/ | head -n 5",
  "find modules -name '*.nix' && git log -n 3",
]) {
  assert.equal(bashIsReadOnly(cmd), true, `expected allowed: ${cmd}`);
}

// Blocked mutating or escape commands
for (const cmd of [
  "",
  "rm -rf /tmp/x",
  "echo hi > /tmp/x",
  "echo $(whoami)",
  "ls & rm -rf /tmp/x",
  "find . -exec rm {} \\;",
  "find . -ok rm {} \\;",
  "find . -okdir sh {} \\;",
  "find . -delete",
  "git -c core.pager=sh log",
  "git -ccore.pager=sh log",
  "git --config-env=core.pager=PAGER log",
  "git --exec-path=/tmp log",
  "git grep --open-files-in-pager=sh foo",
  "git diff --ext-diff",
  "git branch new-branch",
  "git stash drop",
  "nix flake update",
  "sort -o out.txt in.txt",
]) {
  assert.equal(bashIsReadOnly(cmd), false, `expected blocked: ${cmd}`);
}

console.log("modes tests passed");
