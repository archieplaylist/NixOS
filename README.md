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
│   │   ├── desktop.nix      # GNOME/Niri/XFCE/Plasma + PipeWire + flatpak
│   │   ├── gaming.nix       # Steam, GameMode, gamescope, controllers + low-latency audio
│   │   └── hardware.nix     # intel, uefi, laptop, vm-guest slots
│   ├── home/            # home-manager modules (all merge into home.modules.primary)
│   │   ├── core.nix / apps.nix / ai.nix (pi + opencode)
│   │   ├── desktops/ (gnome/niri/xfce/plasma/themes) / easyeffects.nix
│   │   └── scripts/     # yt, tomp3, switch-de, backup-de (+ de-paths shared lists) -> ~/.local/bin
│   └── hosts/           # one file per machine -> nixos.hosts.<name>
└── secrets/             # local secret templates only (never commit real values)
```

Adding a host = add one file under `modules/hosts/` (see `desktop.nix`).
No wiring in `flake.nix`.

## Host flags (`mySystem.*`)

- `enableDesktop` + `desktop = "gnome" | "niri" | "xfce" | "plasma"` — DE + GDM/Ly/LightDM/SDDM, PipeWire, Bluetooth, NetworkManager, Flatpak.
- `enableLaptop` / `enableSSH` / `sshPasswordAuth` / `enableDocker` / `enableTailscale` / `enableVirtualBox` / `enableSmartd`. SSH is key-only by default (`sshAuthorizedKeys`); set `sshPasswordAuth = true` only for bootstrap/legacy clients.
- `enableLuks` / `enableTpm2` / `enableSecureBoot` — fresh-install only (repartition required).
- `flatpakApps`, `gnomeExtensions`, `sshAuthorizedKeys`.
- `appGroups.{browsers,media,office,comms,editor,gaming,dev,work,ai}.enable` — package toggles shared by system + home (`apps.nix` via `osConfig`). Off by default: each host opts in explicitly.

## Application groups (`modules/home/apps.nix`)

- **browsers**: firefox, vivaldi. **media**: vlc, mpv, yt-dlp, ffmpeg, qbittorrent. **office**: joplin, onlyoffice, libreoffice. **comms**: discord (unstable). **editor**: vscode (unstable). **dev**: git, lazygit, nodejs, gh, python3, gnumake. **gaming**: heroic, mangohud, protonplus, bottles. **work** (opt-in): chromium, dbeaver-bin, remmina, filezilla. **ai** (off on `vm`): pi-coding-agent + `~/.pi/agent/` config.
- System side: `gaming.nix` (Steam + GameMode + gamescope + xone/xpadneo + low-latency PipeWire).

## Scripts (`~/.local/bin`)

- `yt <url>` / `yt -a <url>` — video / audio-only to `~/Downloads`.
- `tomp3 file...` — to 192k MP3 in place.
- `switch-de <gnome|niri|xfce|plasma>` — flips `mySystem.desktop`, `nh os boot`, archives dormant DE state to `~/.local/share/de-archive/`. Reboot to apply.
- `backup-de backup [gnome|niri|xfce|plasma|all]|restore <file>|list` — dconf dump/load (gnome) + file tars, newest 3 kept per DE. `switch-de` prompts for a backup when none exists.

## Desktop environments

GNOME (GDM/Wayland), Niri (Ly/Wayland, Noctalia v5 shell, unstable), XFCE (LightDM/X11), Plasma 6 (SDDM/Wayland). Per-host via `mySystem.desktop`; switch with `switch-de`. GNOME extensions are the single source of truth in `mySystem.gnomeExtensions`. Theming (GNOME only, unstable `pkgs.orchis-theme`): Orchis-Dark + Tela-circle-dark + Bibata — Niri/XFCE/Plasma stay stock defaults.

## Flatpak

Declared via nix-flatpak (`desktop.nix` + `mySystem.flatpakApps`). Shared: LocalSend, GearLever, Flatseal (+ ExtensionManager per host, Insomnia on `work`).

## First-time setup

```bash
./setup.sh --list-hosts        # no root needed: see installable hosts
sudo ./setup.sh              # interactive (whiptail menu, plain fallback)
sudo ./setup.sh --yes        # non-interactive
sudo ./setup.sh --luks --tpm2
sudo ./setup.sh --resume       # restore choices after Ctrl-C / disconnect
```

Does: preflight → optional destructive partitioning (installer ISO only, type disk + `WIPE`) → user password hash to `/etc/hashed-password` (never in repo) → pick host → `nixos-install` (ISO) or `nixos-rebuild switch`. See `./setup.sh --help`.

Filesystems are by label (`nixos-root` / `nixos-boot`); LUKS2 is `cryptroot` via disko. With `--luks`, `setup.sh` patches `mySystem.enableLuks` (+ disko device when non-`/dev/sda`) into the host file. Secure Boot needs one-time `sbctl create-keys && sbctl enroll-keys --microsoft` after first boot.

Password later: `printf '%s\n' "$(openssl passwd -6)" | sudo tee /etc/hashed-password` + rebuild, or `sudo passwd $USER`.

## Username Flexibility

The configuration supports flexible usernames via `mySystem.username` (default: `mario`).

### Fresh Install with Custom Username

Use the `--user` flag during installation:

```bash
sudo ./setup.sh --user=alice
# Or answer the username prompt interactively
```

The installer will:
1. Validate the username format (lowercase, alphanumeric, underscores/hyphens)
2. Patch the selected host file with `mySystem.username = "alice"`
3. Configure the system for the specified username
4. Set up home-manager for the new user

### Existing System Username Change

To change the username on an existing system:

1. **Edit the host configuration:**
   ```nix
   # modules/hosts/<host>.nix
   mySystem.username = "newname";
   ```

2. **Rebuild the system:**
   ```bash
   nh os switch -H <host>
   ```

3. **Manual migration steps required:**
   ```bash
   # Create the new user
   sudo useradd -m newname

   # Set password for the new user
   sudo passwd newname

   # Migrate data from old home directory
   sudo rsync -a /home/oldname/ /home/newname/

   # Fix permissions
   sudo chown -R newname:newname /home/newname

   # Remove old user (after verifying everything works)
   sudo userdel oldname
   ```

### Per-Host Usernames

Each host file can specify different usernames:

```nix
# modules/hosts/desktop.nix
mySystem.username = "mario";

# modules/hosts/laptop.nix  
mySystem.username = "alice";
```

To share the repo across machines with different users:
1. Copy the repo to the new machine
2. Change `mySystem.username` in the appropriate host file
3. Run `nh os switch -H <host>`

### Important Notes

- **Live migration not supported:** Changing usernames requires manual data migration
- **Git identity separate:** `mySystem.gitName` and `mySystem.gitEmail` are independent of username
- **State persistence:** The setup script saves username choice in `/var/tmp/nixos-setup.state` for crash recovery
- **Validation:** Usernames must match regex `^[a-z_][a-z0-9_-]*$` (lowercase, no leading digits)

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
- SSH is key-only by default; `mySystem.sshAuthorizedKeys` provides access, `mySystem.sshPasswordAuth = true` re-enables password login (e.g. `work` template: paste pubkey, set `enableSSH = true`, `make check && nh os switch -H work`).
- `programs.nix-ld` ships a minimal lib set; when an unpatched binary misses a lib: `nix run github:nix-community/nix-index-database -- lib/<name>.so`, then add it to `modules/features/base.nix` (nix-ld section).
- OOM handling is `earlyoom` only (no `systemd.oomd`).
