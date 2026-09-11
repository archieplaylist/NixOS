# NixOS Desktop Configuration

Flake-based NixOS 26.05 for Mario's machines, organized with the
[dendritic pattern](https://github.com/mightyiam/dendritic): every Nix file
except the entry point is a top-level (flake-parts) module, auto-imported from
`modules/`. Four hosts: `desktop`, `laptop`, `work`, `vm` (VM guest).

## Layout

```
├── flake.nix            # entry point: flake-parts; auto-imports every module under modules/
├── Makefile             # check, fmt, build, switch
├── .githooks/           # git hooks (install with `make hooks`)
├── modules/             # EVERY .nix file here is a top-level (flake-parts) module
│   ├── options.nix      # slot options: nixos.modules/hosts, home.modules
│   ├── outputs.nix      # nixosConfigurations, checks, devShell, formatter
│   ├── features/        # NixOS modules, merged into slots
│   │   ├── mySystem.nix     # mySystem.* options + GNOME extension source of truth
│   │   ├── base.nix         # locale/firewall/printing, ssh/docker/tailscale, store upkeep, nix-ld, user
│   │   ├── filesystems.nix  # XFS by label, or LUKS2 via disko
│   │   ├── desktop.nix      # GNOME/Plasma/XFCE + PipeWire + flatpak
│   │   ├── gaming.nix       # Steam, GameMode, gamescope, controllers + low-latency audio
│   │   └── hardware.nix     # intel, uefi, laptop, vm-guest slots
│   ├── home/            # home-manager modules (all merge into home.modules.mario)
│   │   ├── core.nix / apps.nix / ai.nix (pi + opencode)
│   │   ├── desktops.nix (gnome/plasma/xfce/themes) / easyeffects.nix
│   │   └── scripts/     # yt, tomp3, switch-de, backup-de -> ~/.local/bin
│   └── hosts/           # one file per machine -> nixos.hosts.<name>
└── secrets/             # local secret templates only (never commit real values)
```

Adding a host = add one file under `modules/hosts/` (see `desktop.nix`).
No wiring in `flake.nix`.

## Host flags (`mySystem.*`)

- `enableDesktop` + `desktop = "gnome" | "plasma" | "xfce"` — DE + GDM/SDDM/LightDM, PipeWire, Bluetooth, NetworkManager, Flatpak.
- `enableLaptop` / `enableSSH` / `enableDocker` / `enableTailscale` / `enableVirtualBox` / `enableSmartd`.
- `enableLuks` / `enableTpm2` / `enableSecureBoot` — fresh-install only (repartition required).
- `flatpakApps`, `gnomeExtensions`, `sshAuthorizedKeys`.
- `appGroups.{browsers,media,office,comms,editor,gaming,dev,work,ai}.enable` — package toggles shared by system + home (`apps.nix` via `osConfig`).

## Application groups (`modules/home/apps.nix`)

- **browsers**: firefox, vivaldi. **media**: vlc, mpv, yt-dlp, ffmpeg, qbittorrent. **office**: joplin, onlyoffice, libreoffice. **comms**: discord (unstable). **editor**: vscode (unstable). **dev**: git, lazygit, nodejs, gh, python3, gnumake. **gaming**: heroic, mangohud, protonplus, bottles. **work** (opt-in): chromium, dbeaver-bin, remmina, filezilla. **ai** (off on `vm`): pi-coding-agent + `~/.pi/agent/` config.
- System side: `gaming.nix` (Steam + GameMode + gamescope + xone/xpadneo + low-latency PipeWire).

## Scripts (`~/.local/bin`)

- `yt <url>` / `yt -a <url>` — video / audio-only to `~/Downloads`.
- `tomp3 file...` — to 192k MP3 in place.
- `switch-de <gnome|plasma|xfce>` — flips `mySystem.desktop`, `nh os boot`, archives dormant DE state to `~/.local/share/de-archive/`. Reboot to apply.
- `backup-de backup [gnome|plasma|xfce|all]|restore <file>|list` — dconf dump/load (gnome) + file tars, newest 3 kept per DE. `switch-de` prompts for a backup when none exists.

## Desktop environments

GNOME (GDM/Wayland), Plasma (SDDM/Wayland, via plasma-manager), XFCE (LightDM/X11). Per-host via `mySystem.desktop`; switch with `switch-de`. GNOME extensions are the single source of truth in `mySystem.gnomeExtensions`. Theming (GNOME only, unstable `pkgs.orchis-theme`): Orchis-Dark + Tela-circle-dark + Bibata — Plasma/XFCE stay stock defaults.

## Flatpak

Declared via nix-flatpak (`desktop.nix` + `mySystem.flatpakApps`). Shared: LocalSend, GearLever, Flatseal (+ ExtensionManager per host, Insomnia on `work`).

## First-time setup

```bash
sudo ./setup.sh              # interactive
sudo ./setup.sh --yes        # non-interactive
sudo ./setup.sh --luks --tpm2
```

Does: preflight → optional destructive partitioning (installer ISO only, type disk + `WIPE`) → user password hash to `/etc/hashed-password` (never in repo) → pick host → `nixos-install` (ISO) or `nixos-rebuild switch`. See `./setup.sh --help`.

Filesystems are by label (`nixos-root` / `nixos-boot`); LUKS2 is `cryptroot` via disko. With `--luks`, `setup.sh` patches `mySystem.enableLuks` (+ disko device when non-`/dev/sda`) into the host file. Secure Boot needs one-time `sbctl create-keys && sbctl enroll-keys --microsoft` after first boot.

Password later: `printf '%s\n' "$(openssl passwd -6)" | sudo tee /etc/hashed-password` + rebuild, or `sudo passwd mario`.

## Day-to-day

```bash
make check   # nix flake check — builds every host, run before push
make fmt     # nix fmt — run before commit
nh os build -H <host>   # dry run
nh os boot -H <host>    # next boot
nh os switch -H <host>  # now (also updates home-manager)
nh clean all            # GC (weekly timer does this automatically)
```

`nix flake update` refreshes all inputs (`nixpkgs-unstable` provides `pkgs.unstable` for discord/vscode/pi). `nix develop` gives nixpkgs-fmt + deadnix + statix. Pre-push hook runs `fmt-check` + `check` (install with `make hooks`).

## Notes

- Boot menu lists generations (systemd-boot, limit 10); `nh os rollback` reverts the last switch.
- `nixpkgs-unstable` + stable both in `flake.lock`; most packages are stable, only fresher apps use `pkgs.unstable`.
- SSH allows password login; `mySystem.sshAuthorizedKeys` is optional extra. `work` template: paste pubkey, set `enableSSH = true`, `make check && nh os switch -H work`.
- `programs.nix-ld` ships a minimal lib set; when an unpatched binary misses a lib: `nix run github:nix-community/nix-index-database -- lib/<name>.so`, then add it to `modules/features/base.nix` (nix-ld section).
- OOM handling is `earlyoom` only (no `systemd.oomd`).
