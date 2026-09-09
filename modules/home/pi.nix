# pi-coding-agent — gated on mySystem.appGroups.ai.enable (all hosts except vm)
{ inputs, ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    {
      config = lib.mkIf osConfig.mySystem.appGroups.ai.enable {
        home.packages = [ pkgs.nodejs pkgs.unstable.pi-coding-agent ];

        # ponytail: telemetry off, update checks stay on (never set PI_OFFLINE=1 globally)
        home.sessionVariables = {
          PI_TELEMETRY = "0";
          PI_OFFLINE = "0";
        };

        # ponytail: per-file entries only — never manage ~/.pi/agent/ as a whole,
        # or imperative `pi install` packages in npm/|git/ get wiped on rebuild.
        # Auth is hybrid: `pi` + `/login` works with zero config; for API keys
        # export them via ~/.bashrc or /run/secrets (see README).
        home.file.".pi/agent/settings.json".text = builtins.toJSON {
          theme = "dark";
          thinking = "high";
          defaultProjectTrust = "ask";
          enableInstallTelemetry = false;
        };

        home.file.".pi/agent/AGENTS.md".text = ''
          # Global agent instructions

          General coding: stdlib first, explicit error handling, smallest diff that works.
          No abstraction, dependency, or config surface without a caller. Tests for logic.

          In this NixOS repo additionally: `nix fmt` before commit, `make check` before push,
          dendritic layout (`modules/` auto-imported, hosts add one file), per-host toggles
          via `mySystem.appGroups.*`, no secrets in git.

          Git: conventional commits (`feat:`/`fix:`/`chore:`), `init.defaultBranch=main`,
          `push.autoSetupRemote=true`. Never commit `result/`, `.direnv/`, or secrets.
          Never print secrets to chat or logs.
        '';

        # ponytail: upstream skill dirs, versioned in flake.lock —
        # update with `nix flake update ponytail caveman`, no hand-rolled copies to drift.
        home.file.".pi/agent/skills/ponytail".source = "${inputs.ponytail}/skills/ponytail";
        home.file.".pi/agent/skills/caveman".source = "${inputs.caveman}/skills/caveman";

        home.file.".pi/agent/prompts/review.md".text = ''
          Review this code for bugs, security issues, and performance problems.
          Focus on: {{focus}}

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
                handler: async (ctx: any, args: string) => {
                  armed = true;
                  const fs = await import("node:fs");
                  fs.writeFileSync("PLAN.md", `# Plan\n\n''${args}\n`);
                  return "Plan written to PLAN.md. Say `approved` to arm edits, `done` to disarm.";
                },
              });
              if (typeof pi.on === "function") {
                pi.on("tool_call", async (event: any) => {
                  if (armed && event?.tool === "edit" && !event?.approved)
                    return { block: true, message: "Plan mode armed — approve first." };
                  return undefined;
                });
              }
            } catch { /* never break pi boot */ }
          }
        '';
      };
    };
}
