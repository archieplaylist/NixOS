# AI agents — pi-coding-agent (pi) + opencode, gated on appGroups.ai.enable.
# Sections merged into one condition, behavior unchanged.
{ inputs, ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    {
      config = lib.mkIf osConfig.mySystem.appGroups.ai.enable {
        home.packages = [
          # ponytail: nodejs overlaps dev group on purpose — ai hosts run with dev off
          pkgs.nodejs
          pkgs.unstable.pi-coding-agent
          pkgs.xdg-utils
          pkgs.unstable.opencode
        ];

        # qmd binary for pi-memory `memory_search` (not in nixpkgs):
        # install once by hand: NPM_CONFIG_PREFIX=~/.local/share/npm-global npm install -g @tobilu/qmd
        # ponytail: no activation-time npm fetch — keeps switches offline and reproducible.
        home.sessionPath = [ "$HOME/.local/share/npm-global/bin" ];
        # ponytail: telemetry off, update checks stay on (never set PI_OFFLINE=1 globally)
        home.sessionVariables = {
          PI_TELEMETRY = "0";
        };

        # ponytail: per-file entries only — never manage ~/.pi/agent/ as a whole,
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
          - Minimize code comments: no obvious/redundant comments; comment only non-obvious logic or `ponytail:` ceilings; prefer self-documenting names over commented code.
        '';

        # ponytail: upstream skill dirs, versioned in flake.lock —
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

          Ponytail: ladder YAGNI → reuse existing → stdlib → native platform → installed dep → one-liner → minimal code; root-cause fix in shared function, not per-caller; no unrequested abstraction/boilerplate; fewest files, shortest working diff; `ponytail:` comment for deliberate ceilings.
          Caveman: terse, drop articles/filler/pleasantries/hedging, fragments OK, short synonyms, no tool-call narration, no decorative tables/emoji, code/error strings verbatim, preserve user's language.

          Output issues sorted by severity with minimal diffs.
        '';

        home.file.".pi/agent/prompts/commit.md".text = ''
          Review staged changes, run `nix fmt` on any Nix files, then write a
          conventional commit message (`feat:`/`fix:`/`chore:`). Never commit secrets,
          `result/`, or `.direnv/`.
        '';

        # ponytail: pi ships no plan mode — this stub adds /plan with a file gate.
        # Defensive no-op if ExtensionAPI drifts (never break `pi` boot or `/reload`).
        home.file.".pi/agent/extensions/plan-mode.ts".text = ''
          export default function (pi: any) {
            try {
              if (!pi || typeof pi.registerCommand !== "function") return;
              let armed = false;
              pi.registerCommand("plan", {
                description: "Write plan to file and require approval before edits",
                handler: async (args: string, ctx: any) => {
                  armed = true;
                  const fs = await import("node:fs");
                  const path = await import("node:path");
                  fs.writeFileSync(path.join(ctx.cwd, "PLAN.md"), `# Plan\n\n''${args}\n`);
                  ctx.ui.notify("Plan written to PLAN.md. Say `approved` to allow edits, `done` to disarm.", "info");
                },
              });
              if (typeof pi.on === "function") {
                pi.on("tool_call", async (event: any) => {
                  if (armed && (event?.toolName === "edit" || event?.toolName === "write"))
                    return { block: true, reason: "Plan mode armed — say `approved` to allow edits." };
                  return undefined;
                });
                pi.on("input", async (event: any, ctx: any) => {
                  const t = (event?.text ?? "").trim().toLowerCase();
                  if (t === "approved" || t.startsWith("approved ") || t === "done" || t.startsWith("done ")) {
                    armed = false;
                    ctx.ui.notify(t === "approved" ? "Edits approved." : "Plan mode disarmed.", "info");
                    return { action: "handled" };
                  }
                  return undefined;
                });
              }
            } catch (e) { console.warn("plan-mode init failed:", e); }
          }
        '';

        # ponytail: same upstream skill dirs as pi above, versioned in flake.lock.
        # Per-dir entries only — never manage ~/.config/opencode/ as a whole,
        # or imperative `plugin` installs in opencode.json get wiped on rebuild.
        xdg.configFile."opencode/skills/ponytail".source = "${inputs.ponytail}/skills/ponytail";
        xdg.configFile."opencode/skills/caveman".source = "${inputs.caveman}/skills/caveman";
      };
    };
}
