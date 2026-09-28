# AI agents — pi-coding-agent (pi) + opencode + llama.cpp, gated on appGroups.ai.enable.
# Sections merged into one condition, behavior unchanged.
{ inputs, ... }: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }:
    {
      config = lib.mkIf osConfig.mySystem.appGroups.ai.enable {
        home.packages = [
          # nodejs overlaps dev group on purpose — ai hosts run with dev off
          pkgs.nodejs
          pkgs.unstable.pi-coding-agent
          pkgs.xdg-utils
          pkgs.opencode
          pkgs.unstable.llama-cpp
        ];

        # qmd binary for pi-memory `memory_search` (not in nixpkgs):
        # install once by hand: NPM_CONFIG_PREFIX=~/.local/share/npm-global npm install -g @tobilu/qmd
        # no activation-time npm fetch — keeps switches offline and reproducible.
        home.sessionPath = [ "$HOME/.local/share/npm-global/bin" ];
        # telemetry off, update checks stay on (never set PI_OFFLINE=1 globally)
        home.sessionVariables = {
          PI_TELEMETRY = "0";
        };

        # per-file entries only — never manage ~/.pi/agent/ as a whole,
        # or imperative `pi install` packages in npm/|git/ get wiped on rebuild.
        # Auth is hybrid: `pi` + `/login` works with zero config; for API keys
        # export them via ~/.bashrc or /run/secrets (see README).
        # Packages are declarative here so they survive rebuilds —
        # pi auto-installs missing npm packages from this list on next startup.
        home.file.".pi/agent/settings.json".text = builtins.toJSON {
          theme = "dark";
          thinking = "high";
          defaultProjectTrust = "ask";
          enableInstallTelemetry = false;
          packages = [ "npm:pi-web-access" "npm:pi-memory" ];
        };

        # Global instructions only — repo rules live in <repo>/AGENTS.md (context file).
        home.file.".pi/agent/AGENTS.md".text = ''
          # Global agent instructions

          - Prefer stdlib / platform features over new dependencies; no new
            abstraction, dependency, or config surface without a direct caller.
          - Handle errors explicitly at the boundary; never swallow failures silently.
          - Make the smallest diff that works; don't refactor unrelated code.
          - Add or update tests for logic changes; skip tests for trivial renames.
          - Never print secrets to chat or logs.
          - Always apply `ponytail:full` + `caveman:full` for code/write/review/audit/read — read `~/.pi/agent/skills/ponytail/SKILL.md` and `~/.pi/agent/skills/caveman/SKILL.md` if needed. Ponytail = ladder YAGNI→reuse→stdlib→native→dep→one-liner; caveman = terse, no filler/narration.
          - Minimize code comments: no obvious/redundant comments; comment only non-obvious logic; prefer self-documenting names over commented code.
        '';

        # upstream skill dirs, versioned in flake.lock —
        # update with `nix flake update ponytail caveman`, no hand-rolled copies to drift.
        home.file.".pi/agent/skills/ponytail".source = "${inputs.ponytail}/skills/ponytail";
        home.file.".pi/agent/skills/caveman".source = "${inputs.caveman}/skills/caveman";

        home.file.".pi/agent/prompts/review.md".text = ''
          ---
          description: Review code — always ponytail + caveman
          ---
          Apply skills `ponytail:full` and `caveman:full` — always. Read `~/.pi/agent/skills/ponytail/SKILL.md` and `~/.pi/agent/skills/caveman/SKILL.md` if needed.

          Review this code for bugs, security issues, and performance problems.
          Focus on: {{focus}}

          Ponytail: ladder YAGNI → reuse existing → stdlib → native platform → installed dep → one-liner → minimal code; root-cause fix in shared function, not per-caller; no unrequested abstraction/boilerplate; fewest files, shortest working diff; plain comments, no skill tags.
          Caveman: terse, drop articles/filler/pleasantries/hedging, fragments OK, short synonyms, no tool-call narration, no decorative tables/emoji, code/error strings verbatim, preserve user's language.

          Output issues sorted by severity with minimal diffs.
        '';

        home.file.".pi/agent/prompts/commit.md".text = ''
          Review staged changes, run `nix fmt` on any Nix files, then write a
          conventional commit message (`feat:`/`fix:`/`chore:`). Never commit secrets,
          `result/`, or `.direnv/`.
        '';

        # pi ships no plan/ask mode - this adds both, sharing one permission
        # layer: /plan (read-only until `approved`), /ask (read-only Q&A),
        # --plan/--ask, and the `ask` / `ask_permission` tools. One mode
        # variable, one read-only bash allowlist, so the rules cannot drift.
        # Defensive no-op if ExtensionAPI drifts (never break `pi` boot or
        # `/reload`). Re-check on each `nix flake update`: drop this once pi
        # ships native modes, and smoke-test `/plan` + `/ask` after upgrades.
        home.file.".pi/agent/extensions/modes.ts".text = ''
          import * as fs from "node:fs";
          import * as path from "node:path";
          import { Type } from "typebox";

          // pi ships no plan/ask mode. This adds both, sharing one permission layer:
          //   /plan  - read-only while planning, `approved` unlocks edits (scoped)
          //   /ask   - read-only Q&A, never writes anything
          // Mutating tools leave the active set and are blocked in tool_call; bash is
          // narrowed to a read-only allowlist rather than cut off, so the agent can
          // still gather evidence instead of guessing. One allowlist, two modes, so the
          // rules cannot drift apart.

          type Mode = "off" | "ask" | "plan";

          const WRITE_TOOLS = ["edit", "write", "powershell"];

          const GOAL_MARKER = "<!-- one paragraph: what is true when this is done -->";

          const PLAN_TEMPLATE = [
            "# Plan",
            "",
            "## Goal",
            "",
            GOAL_MARKER,
            "",
            "## Changes",
            "",
            "<!-- concrete edits, file by file. Name every path: `approved` locks edits to these. -->",
            "",
            "## Not doing",
            "",
            "## Verification",
            "",
            "<!-- the exact command that proves it works -->",
            "",
            "## Risks",
            "",
            "<!-- what could break, and the blast radius -->",
            "",
          ].join("\n");

          const PLAN_CONTEXT = [
            "[PLAN MODE ACTIVE] Plan first, then stop.",
            "",
            "1. Investigate with read/grep/find/ls and read-only bash. Do not assume; look.",
            "2. Collect every open decision, then ask ONCE via the `ask` tool (one call, all questions, your recommendation first). Never guess a decision with real cost - scope, data model, migrations, deleting or rewriting a file you are unsure about.",
            "3. If you need one specific blocked action to answer a question (e.g. `nix build` to confirm a config is valid), call `ask_permission` once. Do not ask to leave plan mode.",
            "4. Write the plan to PLAN.md in this shape:",
            "   ## Goal - one paragraph, what is true when this is done",
            "   ## Changes - concrete edits, file by file; name every path so `approved` can lock scope",
            "   ## Not doing - what you are deliberately leaving alone",
            "   ## Verification - the exact command that proves it works",
            "   ## Risks - what could break, and the blast radius",
            "5. Stop and wait. Say `approved` to unlock edits (paths named in PLAN.md become the locked scope), `approved <path>` to set the scope explicitly, `done` to abandon.",
          ].join("\n");

          const ASK_CONTEXT = [
            "[ASK MODE ACTIVE] Read-only Q&A. Answer in words.",
            "",
            "1. Investigate with read/grep/find/ls and read-only bash (ls, cat, grep, find, git status/log/diff, nix eval). Verify claims from the code, not from memory.",
            "2. Batch every open decision into ONE `ask` call rather than guessing or asking serially. Put your recommendation first.",
            "3. Need one specific blocked action to check a claim? Call `ask_permission` once instead of asking to leave ask mode.",
            "4. Do not create files, docs, notes or summaries as a side effect. If the answer implies a change, describe it in prose and stop.",
            "5. Never call edit, write or powershell.",
          ].join("\n");

          const READ_ONLY_CMDS = [
            "ls", "pwd", "cat", "head", "tail", "wc", "stat", "file", "du", "df", "tree",
            "grep", "rg", "ag", "find", "fd", "diff", "cmp", "which", "type", "echo",
            "printf", "date", "uname", "whoami", "id", "hostname", "printenv",
            "realpath", "basename", "dirname", "sort", "uniq", "cut", "nl", "tac",
            "column", "jq", "strings", "od", "xxd", "seq", "test", "true", "false", "man",
            "git", "nix",
          ];
          // Deliberately absent: env (it can exec anything), xargs, awk, sed, eval, gh,
          // glab, docker, kubectl, systemctl, sudo, ssh, scp, rsync, npm, pip, cargo.
          // They read like inspection tools but their arguments mutate state, and an
          // allowlist that leaks is worse than a block.

          // git verbs that never write, whatever the flags.
          const GIT_READ = [
            "status", "log", "diff", "show", "blame", "ls-files", "rev-parse", "describe",
            "shortlog", "reflog", "cat-file", "count-objects", "symbolic-ref", "grep",
          ];
          // git verbs that write once given a name (`git branch foo`, `git stash drop`).
          // Allowed only with no positional argument, i.e. the listing forms.
          const GIT_LIST_ONLY = ["branch", "remote", "tag", "stash"];

          // nix verbs that never write. No `flake` (update writes the lock), no `store`
          // (delete), no `registry` (add), no `hash` (convert), no nix-store (--delete).
          const NIX_READ = ["eval", "path-info", "why-depends"];

          function firstSubcommand(parts: string[]): string | undefined {
            return parts.slice(1).find((a) => a[0] !== "-");
          }

          function segmentIsReadOnly(seg: string): boolean {
            // find -delete/-exec/-fprint and any --output write files.
            if (/-delete|-exec|-fprint|-fls|--output/.test(seg)) return false;
            const parts = seg.split(/\s+/).filter(Boolean);
            if (parts.length === 0) return false;
            const bin = parts[0].replace(/^.*\//, "");
            if (READ_ONLY_CMDS.indexOf(bin) === -1) return false;
            if (bin === "sort" && parts.some((a) => a === "-o")) return false;
            if (bin === "git") {
              const sub = firstSubcommand(parts);
              if (sub === undefined) return false;
              if (GIT_READ.indexOf(sub) !== -1) return true;
              if (GIT_LIST_ONLY.indexOf(sub) === -1) return false;
              // `git stash list` is the one positional that stays read-only.
              const rest = parts.slice(parts.indexOf(sub) + 1).filter((a) => a[0] !== "-");
              return rest.length === 0 || (sub === "stash" && rest[0] === "list");
            }
            if (bin === "nix") {
              const sub = firstSubcommand(parts);
              if (sub === undefined) return parts.slice(1).every((a) => a[0] === "-");
              return NIX_READ.indexOf(sub) !== -1;
            }
            return true;
          }

          // Redirection, subshells and pipelines are rejected or split, never trusted.
          function bashIsReadOnly(command: string): boolean {
            const cmd = String(command ?? "");
            if (cmd.trim() === "") return false;
            if (/[><`]/.test(cmd) || cmd.includes("$(") || /\btee\b/.test(cmd)) return false;
            const segments = cmd.split(/&&|\|\||[;|\n]/).map((s) => s.trim()).filter(Boolean);
            if (segments.length === 0) return false;
            return segments.every(segmentIsReadOnly);
          }

          const CODE_PATH = /`([^`]+)`|"([^"]+)"|'([^']+)'/g;

          function looksLikePath(value: string): boolean {
            const v = value.trim();
            if (v === "" || /\s/.test(v)) return false;
            return v.indexOf("/") !== -1 || /\.[A-Za-z0-9]{1,8}$/.test(v);
          }

          function extractScope(markdown: string): string[] {
            const out: string[] = [];
            CODE_PATH.lastIndex = 0;
            let m: RegExpExecArray | null;
            while ((m = CODE_PATH.exec(markdown)) !== null) {
              const candidate = (m[1] ?? m[2] ?? m[3] ?? "").trim();
              if (looksLikePath(candidate) && out.indexOf(candidate) === -1) out.push(candidate);
            }
            return out;
          }

          function inScope(target: string, scope: string[]): boolean {
            const t = target.replace(/^\.\//, "");
            return scope.some((entry) => {
              const s = entry.replace(/^\.\//, "").replace(/\/+$/, "");
              return t === s || t.startsWith(s + "/") || s.startsWith(t + "/");
            });
          }

          function buildPlan(goal: string): string {
            const lines = PLAN_TEMPLATE.split("\n");
            if (goal !== "") {
              const at = lines.indexOf(GOAL_MARKER);
              if (at !== -1) lines[at] = goal;
            }
            return lines.join("\n");
          }

          const AskParams = Type.Object({
            questions: Type.Array(
              Type.Object({
                question: Type.String({ description: "The decision to make. State what it costs to get wrong." }),
                options: Type.Optional(Type.Array(Type.String(), { description: "Choices. Put your recommendation first." })),
                recommendation: Type.Optional(Type.String()),
              }),
              { minItems: 1, maxItems: 6 },
            ),
          });

          const AskPermissionParams = Type.Object({
            tool: Type.String({ description: "Blocked tool to allow once: bash, edit, write or powershell." }),
            reason: Type.String({ description: "Why the answer needs this action, and what it will be used for." }),
          });

          export default function (pi: any) {
            try {
              if (!pi || typeof pi.registerCommand !== "function") return;

              // One variable, so "both modes armed" is unrepresentable.
              let mode: Mode = "off";
              let savedTools: string[] = [];
              let scope: string[] | null = null;
              let grants: Record<string, number> = {};

              const setStatus = (ctx: any) => {
                if (!ctx?.ui || typeof ctx.ui.setStatus !== "function") return;
                if (mode !== "off") ctx.ui.setStatus("mode", mode);
                else ctx.ui.setStatus("mode", scope ? "plan:scope" : undefined);
              };

              const readPlan = (cwd: string): string => {
                try {
                  return String(fs.readFileSync(path.join(cwd, "PLAN.md"), "utf-8"));
                } catch {
                  return "";
                }
              };

              const setMode = (next: Mode) => {
                if (next === mode) return;
                const wasOff = mode === "off";
                mode = next;
                if (next === "off") {
                  try {
                    if (typeof pi.setActiveTools === "function" && savedTools.length > 0) pi.setActiveTools(savedTools);
                  } catch { /* runtime not bound yet */ }
                  savedTools = [];
                } else {
                  scope = null;
                  grants = {};
                  // Snapshot only when leaving off. Switching ask <-> plan must not
                  // re-snapshot the already-filtered list, or nothing can be restored.
                  if (wasOff) {
                    try {
                      savedTools = typeof pi.getActiveTools === "function" ? pi.getActiveTools().slice() : [];
                      if (typeof pi.setActiveTools === "function" && savedTools.length > 0)
                        pi.setActiveTools(savedTools.filter((name: string) => WRITE_TOOLS.indexOf(name) === -1));
                    } catch { /* runtime not bound yet; the tool_call gate still applies */ }
                  }
                }
              };

              const enter = (ctx: any, next: Mode, note: string) => {
                const dropped = mode !== "off" && mode !== next ? mode : null;
                setMode(next);
                setStatus(ctx);
                ctx.ui.notify((dropped ? "Left " + dropped + " mode. " : "") + note, "info");
              };

              const approve = (ctx: any, arg: string) => {
                const found = arg ? [] : extractScope(readPlan(ctx.cwd));
                scope = arg ? arg.split(/\s+/) : found.length > 0 ? found : null;
                setMode("off");
                setStatus(ctx);
                ctx.ui.notify(scope
                  ? "Edits approved" + (arg ? " for: " + scope.join(", ") : ", scope locked to " + scope.length + " path(s) in PLAN.md")
                  : ", unscoped (no paths found in PLAN.md)", "info");
              };

              pi.registerCommand("plan", {
                description: "Plan mode: read-only until `approved` (/plan <goal> seeds PLAN.md)",
                getArgumentCompletions: () => [{ value: "approved" }, { value: "done" }],
                handler: async (args: string, ctx: any) => {
                  const arg = (args ?? "").trim();
                  const lower = arg.toLowerCase();
                  if (lower === "approved" || lower === "approve") return approve(ctx, "");
                  if (lower.startsWith("approved ")) return approve(ctx, arg.slice("approved ".length).trim());
                  if (lower === "done" || lower === "off" || lower === "abort") {
                    const was = mode;
                    setMode("off");
                    setStatus(ctx);
                    ctx.ui.notify(was === "plan" ? "Left plan mode." : "Not in plan mode.", "info");
                    return;
                  }
                  if (mode !== "plan") {
                    enter(ctx, "plan", "Investigate, then fill in PLAN.md. Say `approved` to unlock edits, `done` to abandon.");
                  } else {
                    ctx.ui.notify("Plan mode already armed. Say `approved` to unlock edits, `done` to abandon.", "info");
                  }
                  fs.writeFileSync(path.join(ctx.cwd, "PLAN.md"), buildPlan(arg));
                },
              });

              pi.registerCommand("ask", {
                description: "Ask mode: read-only Q&A, never writes (/ask off to exit)",
                getArgumentCompletions: () => [{ value: "off" }],
                handler: async (args: string, ctx: any) => {
                  const lower = (args ?? "").trim().toLowerCase();
                  if (lower === "off" || lower === "done" || lower === "exit") {
                    if (mode === "ask") return enter(ctx, "off", "Ask mode off. Full access restored.");
                    ctx.ui.notify(mode === "plan" ? "Not in ask mode. `/plan done` leaves plan mode." : "Not in ask mode.", "info");
                    return;
                  }
                  if (lower === "on") return enter(ctx, "ask", "Ask mode on. Read-only: edit, write and non-read-only bash are blocked. /ask off to exit.");
                  if (mode === "ask") return enter(ctx, "off", "Ask mode off. Full access restored.");
                  enter(ctx, "ask", "Ask mode on. Read-only: edit, write and non-read-only bash are blocked. /ask off to exit.");
                },
              });

              pi.registerFlag("plan", {
                description: "Start in plan mode (read-only until `approved`)",
                type: "boolean",
                default: false,
              });
              pi.registerFlag("ask", {
                description: "Start in ask mode (read-only Q&A)",
                type: "boolean",
                default: false,
              });

              if (typeof pi.registerTool === "function") {
                pi.registerTool({
                  name: "ask",
                  label: "Ask",
                  description:
                    "Ask the user a batch of questions and wait for answers. Collect every open decision into ONE call instead of asking serially, and put your recommendation first in `options`. Read-only, available in both plan and ask mode. Use it instead of guessing a decision with real cost.",
                  parameters: AskParams,
                  async execute(_id: string, params: any, _signal: any, _onUpdate: any, ctx: any) {
                    if (!ctx?.hasUI)
                      return { content: [{ type: "text", text: "No interactive UI available. Ask in prose instead." }], isError: true };
                    const answers: string[] = [];
                    for (const q of params.questions) {
                      const title = q.question + (q.recommendation ? "  [" + q.recommendation + "]" : "");
                      const answer = q.options && q.options.length > 0
                        ? await ctx.ui.select(title, q.options)
                        : await ctx.ui.input(title, q.recommendation);
                      answers.push(answer ? "- " + q.question + " -> " + answer : "- " + q.question + " -> (unanswered)");
                    }
                    return { content: [{ type: "text", text: "Answers:\n" + answers.join("\n") }] };
                  },
                });

                pi.registerTool({
                  name: "ask_permission",
                  label: "Ask permission",
                  description:
                    "Request one specific blocked action (usually a `bash` command needed to verify a claim). Shows a confirmation dialog; on approval that tool runs exactly once. Prefer this over asking to leave the current mode.",
                  parameters: AskPermissionParams,
                  async execute(_id: string, params: any, _signal: any, _onUpdate: any, ctx: any) {
                    const tool = String(params.tool ?? "");
                    if (mode === "off")
                      return { content: [{ type: "text", text: "No mode is active, so nothing is blocked. Run `" + tool + "` directly." }], isError: true };
                    if (WRITE_TOOLS.indexOf(tool) === -1 && tool !== "bash")
                      return { content: [{ type: "text", text: "`" + tool + "` is not blocked. Run it directly." }], isError: true };
                    if (ctx?.hasUI !== true)
                      return { content: [{ type: "text", text: "No interactive UI to confirm with. Ask in prose instead." }], isError: true };
                    const ok = await ctx.ui.confirm("Allow " + tool + " once?", String(params.reason ?? ""));
                    if (!ok) return { content: [{ type: "text", text: "Denied. Staying in " + mode + " mode - work around the missing check." }] };
                    grants[tool] = (grants[tool] ?? 0) + 1;
                    return { content: [{ type: "text", text: "Granted: `" + tool + "` allowed for the next call. Use it now." }] };
                  },
                });
              }

              if (typeof pi.on === "function") {
                pi.on("session_start", async (_event: any, ctx: any) => {
                  const wantPlan = pi.getFlag && pi.getFlag("plan") === true;
                  const wantAsk = pi.getFlag && pi.getFlag("ask") === true;
                  if (wantPlan) {
                    setMode("plan");
                    if (wantAsk) ctx.ui.notify("Both --plan and --ask given; using plan mode.", "info");
                  } else if (wantAsk) {
                    setMode("ask");
                  }
                  setStatus(ctx);
                });

                pi.on("before_agent_start", async () => {
                  if (mode === "off") return undefined;
                  return {
                    message: {
                      customType: "mode-context",
                      content: mode === "plan" ? PLAN_CONTEXT : ASK_CONTEXT,
                      display: false,
                    },
                  };
                });

                pi.on("tool_call", async (event: any) => {
                  const tool = event?.toolName;
                  if (mode !== "off") {
                    const label = mode === "plan" ? "Plan mode" : "Ask mode";
                    const suffix = " Call `ask_permission` if you need this one action to verify something.";
                    if (WRITE_TOOLS.indexOf(tool) !== -1) {
                      const left = grants[tool] ?? 0;
                      if (left > 0) {
                        grants[tool] = left - 1;
                        return undefined;
                      }
                      return {
                        block: true,
                        reason: label + ": `" + tool + "` is blocked. Investigate with read/grep/find/ls and read-only bash, ask decisions with `ask`." + suffix,
                      };
                    }
                    if (tool === "bash" && !bashIsReadOnly(event.input?.command)) {
                      const left = grants.bash ?? 0;
                      if (left > 0) {
                        grants.bash = left - 1;
                        return undefined;
                      }
                      return {
                        block: true,
                        reason: label + ": that bash command is not on the read-only allowlist. Read-only commands (ls, cat, grep, find, git status/log/diff, nix eval) still work." + suffix,
                      };
                    }
                    return undefined;
                  }
                  // Mode is off. If an approved plan named a scope, leaving it needs a
                  // new approval rather than a silent expansion of the change.
                  if (scope && tool === "bash")
                    return { block: true, reason: "Plan scope lock is active (bash is unscoped). Say `approved` to release it." };
                  if (scope) {
                    const target = typeof event.input?.path === "string" ? event.input.path : null;
                    if (target !== null && !inScope(target, scope)) {
                      scope = null;
                      return {
                        block: true,
                        reason: "`" + target + "` is outside the approved plan scope. Scope lock released. Say `approved " + target + "` to re-lock to it, or `approved` to allow all edits.",
                      };
                    }
                  }
                  return undefined;
                });

                pi.on("input", async (event: any, ctx: any) => {
                  // `approved` / `done` are plan-mode words only; in ask mode they are
                  // ordinary text and must reach the model untouched.
                  if (mode !== "plan") return undefined;
                  const text = (event?.text ?? "").trim();
                  const lower = text.toLowerCase();
                  if (lower === "done") {
                    setMode("off");
                    setStatus(ctx);
                    ctx.ui.notify("Left plan mode.", "info");
                    return { action: "handled" };
                  }
                  if (lower === "approved" || lower.startsWith("approved ")) {
                    approve(ctx, lower === "approved" ? "" : text.slice("approved ".length).trim());
                    return { action: "handled" };
                  }
                  return undefined;
                });
              }
            } catch (e) {
              console.warn("modes init failed:", e);
            }
          }
        '';

        # same upstream skill dirs as pi above, versioned in flake.lock.
        # Per-dir entries only — never manage ~/.config/opencode/ as a whole,
        # or imperative `plugin` installs in opencode.json get wiped on rebuild.
        # v2 discovers skills under ~/.config/opencode/skills.
        xdg.configFile =
          let
            sources = {
              ponytail = "${inputs.ponytail}/skills/ponytail";
              caveman = "${inputs.caveman}/skills/caveman";
            };
          in
          lib.mapAttrs' (name: src: lib.nameValuePair "opencode/skills/${name}" { source = src; }) sources;
      };
    };
}
