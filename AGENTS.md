# Agent instructions for this repo (NixOS flake, dendritic)

## Layout

- Every `.nix` under `modules/` is a top-level flake-parts module, auto-imported.
  No wiring in `flake.nix`.
- `modules/options.nix` = slots (`nixos.*`, `home.*`); `modules/outputs.nix` =
  `nixosConfigurations` + checks + devShell.
- `modules/features/` = system config, `modules/home/` = home-manager,
  `modules/hosts/<name>.nix` = one file per machine.
- Adding a host = add one file under `modules/hosts/` (copy `desktop.nix`).

## Per-host toggles

- Gate system/home packages behind `mySystem.*` flags and
  `mySystem.appGroups.*` (`apps.nix` reads via `osConfig`).
- `ai` group is off on `vm`; don't enable heavy packages there.

## Workflow

- `nix fmt` before commit; `make check` (`nix flake check`, builds every host)
  before push. Pre-push hook runs both (`make hooks` to install).
- Dry run with `nh os build -H <host>`; activate with `nh os switch -H <host>`.
- `nix flake update` refreshes all inputs; `pkgs.unstable` is only for apps
  that need fresher versions (discord, vscode, pi, …), stable otherwise.
- Use `nix develop` shell (nixpkgs-fmt + deadnix + statix) for linting.

## Skills and tools (pi)

- `ponytail` skill: smallest working solution first, stdlib before dependencies.
  `caveman` skill: terse, literal, minimal-diff edits.
- `web_search` for docs/API lookup, `fetch_content` for URLs, repos, PDFs,
  YouTube/local video. Zero-config; keys go in `~/.pi/web-search.json`.
- `/plan` writes `PLAN.md` and gates edits behind approval; `/review` (prompt)
  for bug/security/perf review sorted by severity with minimal diffs.

## Git

- Conventional commits (`feat:` / `fix:` / `chore:`); `init.defaultBranch=main`,
  `push.autoSetupRemote=true`.
- Never commit `result/`, `.direnv/`, or secrets. `secrets/` holds local
  templates only — real values live in `/etc/` or env, never in git.
- Never print secrets to chat or logs.
