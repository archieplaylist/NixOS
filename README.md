# NixOS Desktop Configuration

A modular, flake-based NixOS configuration for Mario's machines (NixOS 26.05,
GNOME, Intel), organized with the
[dendritic pattern](https://github.com/mightyiam/dendritic): every Nix file
except the entry point is a top-level (flake-parts) module, auto-imported from
`modules/`. Four hosts share the same baseline: `nixos-desktop`,
`nixos-laptop`, `nixos-work`, and `vm-host` (a VM guest).

## Layout

```
├── flake.nix            # entry point: flake-parts; auto-imports every module under modules/
├── Makefile             # day-to-day commands: check, fmt, update, rebuild
├── .githooks/           # git hooks (install with `make hooks`)
├── modules/             # EVERY .nix file here is a top-level (flake-parts) module
│   ├── options.nix      # top-level slot options: nixos.modules/hosts, home.modules
│   ├── outputs.nix      # flake wiring: nixosConfigurations, checks, devShell, formatter
│   ├── features/        # NixOS feature modules, each merging into a slot
│   │   ├── mySystem.nix     # mySystem.* options + GNOME extension source of truth
│   │   ├── basics.nix       # locale, kernel, nix, firewall, fonts, ...
│   │   ├── optimisation.nix # store/disk maintenance: GC, TRIM, zram, smartd, journald
│   │   ├── services.nix     # ssh, docker, tailscale, virtualbox
│   │   ├── secrets.nix      # sops-nix
│   │   ├── users.nix        # mario user
│   │   ├── filesystems.nix  # XFS layout
│   │   ├── desktop.nix      # GNOME desktop
│   │   ├── audio.nix        # PipeWire + low-latency gaming audio
│   │   ├── gaming.nix       # Steam, GameMode, gamescope, controllers
│   │   └── hardware/        # intel, uefi (systemd-boot), laptop, vm-guest
│   ├── home/            # home-manager modules (all merge into home.modules.mario)
│   │   ├── user.nix     # user identity + XDG/session settings
│   │   ├── shell.nix    # bash, direnv, ~/.local/bin scripts (yt, tomp3)
│   │   ├── apps.nix     # user packages, gated on mySystem.appGroups.*
│   │   ├── gnome.nix    # GNOME dconf (extensions, theme, tweaks)
│   │   ├── themes.nix   # WhiteSur dark GTK/icon/cursor + shell theme
│   │   ├── tooling.nix  # git config + global excludes
│   │   ├── fastfetch.nix
│   │   └── scripts/     # plain bash scripts -> ~/.local/bin
│   └── hosts/           # per-machine modules (imports + mySystem flags)
│       └── <host>.nix   # e.g. nixos-desktop.nix -> nixos.hosts.nixos-desktop
└── secrets/             # sops-nix placeholders (encrypted secrets never in git)
```

## Dendritic pattern

Lower-level modules (NixOS and home-manager) are stored as **option values**
of the top-level flake-parts configuration (`lib.types.deferredModule` in
`modules/options.nix`):

- `nixos.modules.<slot>` — NixOS feature modules, merged by slot name
  (`base`, `desktop`, `intel`, `uefi`, `laptop`, `vm-guest`). Feature files
  in `modules/features/` merge into these slots.
- `nixos.hosts.<name>` — one NixOS module per machine, whose key is the flake
  output name. Host files in `modules/hosts/` set it, importing the feature
  slots they need plus their `mySystem` flags.
- `home.modules.<user>` — home-manager modules, all merged into one slot per
  user (single user `mario`), wired to home-manager in `modules/outputs.nix`.

Since every file is a top-level module, files can be moved and renamed freely
(paths only *name* the feature), and adding a machine is just adding one file —
no wiring in `flake.nix` (see "Adding a host").

## Host flags

Each host file sets `mySystem` flags (defined in `modules/features/mySystem.nix`):

- `mySystem.enableDesktop` — GNOME via GDM, PipeWire, Bluetooth, NetworkManager,
  Flatpak daemon, GNOME extensions.
- `mySystem.enableLaptop` — power-profiles-daemon + lid handling.
- `mySystem.enableSSH` / `enableDocker` / `enableTailscale` / `enableVirtualBox` / `enableSops`.
- `mySystem.flatpakApps` — declarative Flatpak apps (nix-flatpak).
- `mySystem.gnomeExtensions` — single source of truth for GNOME extensions.
- `mySystem.appGroups.{general,gaming,dev,work}.enable` — application group
  toggles used by **both** the system side (`desktop.nix`, `audio.nix`,
  `gaming.nix`) and the user side
  (`modules/home/apps.nix` via `osConfig`). This is the per-host switch for the
  package groups below.

## Adding a host

1. Create `modules/hosts/new-host.nix`:

   ```nix
   { config, ... }: {
     config.nixos.hosts.new-host = {
       imports = [
         config.nixos.modules.base
         config.nixos.modules.desktop   # only for desktop hosts
         config.nixos.modules.intel     # only for Intel hardware
         config.nixos.modules.uefi
       ];
       mySystem.hostname = "new-host";
       # ... any mySystem flags you need (see "Host flags")
     };
   }
   ```

2. That's it — the host is auto-imported and becomes
   `nixosConfigurations.new-host` (flake.nix derives all outputs from the
   `nixos.hosts` slots, so nothing else needs to change).
3. Set `mySystem.hostname` (filesystems are referenced by label — see the
   partition step below).
4. Toggle application groups if needed, e.g.
   `mySystem.appGroups.dev.enable = false;`.

## Application groups

User packages live in `modules/home/apps.nix`, each group gated behind its
`mySystem.appGroups.<group>.enable` flag:

- **general** (default on): Firefox, Chromium, Vivaldi, VLC, mpv, yt-dlp,
  ffmpeg, Discord (from nixpkgs-unstable), Joplin, OnlyOffice, LibreOffice,
  VS Code.
- **dev** (default on): Node.js, GitHub CLI, docker-compose, jq, yq.
- **gaming** (default on): Heroic, MangoHud, Cartridges, goverlay, OpenMW,
  Daggerfall Unity, SuperTuxKart, vulkan-tools (user packages). At the system
  level (`gaming.nix`): Steam (32-bit OpenGL + Remote Play/Dedicated
  Server/LAN transfer firewall + Proton env overrides), GameMode (with the
  GNOME shell extension), gamescope (`capSysNice` + `--rt --adaptive-sync`),
  and Xbox/Steam controller support (xone, xpadneo, steam-hardware).
- **work** (default off, opt-in): dbeaver-bin (database client), FileZilla,
  Remmina. Often combined with `mySystem.enableVirtualBox = true;`
  (`services.nix` builds the vboxdrv kernel module, `users.nix` adds `mario`
  to `vboxusers` for USB passthrough).

## Custom scripts

`modules/home/scripts/` holds plain bash scripts installed as `~/.local/bin` (put on
PATH via `home.sessionPath` in `modules/home/user.nix`):

- `yt <url>` — best mp4 video + m4a audio; `yt -a <url>` — audio-only m4a.
  Downloads go to `~/Downloads`.
- `tomp3 file...` — converts any ffmpeg-supported file to a 192 kbps MP3 in
  place.

## Flatpak

Flatpak apps are declared declaratively via
[nix-flatpak](https://github.com/gmodena/nix-flatpak). The daemon and wiring
live in `modules/features/desktop.nix`; each host picks its own apps with
`mySystem.flatpakApps = [ ... ]`. Current shared set: EasyEffects, LocalSend,
GearLever, Flatseal, Extension Manager (`nixos-work` additionally has
Insomnia).

## First-time setup

The quickest way is the setup script:

```bash
./setup.sh          # interactive
./setup.sh --yes    # answer yes to everything
```

It will:
1. check the repo layout and required tools,
2. **optionally partition + format a disk** (only offered on the NixOS
   installer ISO; destructive — requires typing the device path and `WIPE`),
3. **set the user password**: hashed (SHA-512); the hash is written to
   `/etc/hashed-password` on the target system during the deploy step (never
   stored in the repo),
4. create a sops age key and `secrets/.sops.yaml` from the example,
5. create an encrypted (empty) `secrets/secrets.yaml`, and
6. let you pick a host and run `nixos-rebuild switch`.

Filesystems are referenced by **label** (`/dev/disk/by-label/nixos-root` for
`/`, `/dev/disk/by-label/nixos-boot` for `/boot`), which the partition step
creates — no UUID detection needed.

> **Note on the password**: the SHA-512 hash is stored on the machine at
> `/etc/hashed-password`, read at **every system activation** through
> `users.users.mario.hashedPasswordFile` (`modules/features/users.nix`). It
> never lives in the repo, so there is no git interaction and nothing for a
> fresh clone to leak. The hash path itself is always set in the config; if
> the file is missing on a machine, activation only warns and `mario` has no
> password until one is provisioned. To change it later, re-run `./setup.sh`
> or run `sudo passwd mario` on the machine.

Partitioning creates this layout on the selected disk (GPT, XFS):

```
/dev/sdX
├── 1: ESP  1 GiB  vfat (label nixos-boot)
└── 2: root  rest  xfs  (label nixos-root)
```

The nix store and all system/user state live on the root filesystem — no
subvolumes, no `/persist`. Swap is handled with zram (`zramSwap.enable`), so
no swap partition is needed. The partition step refuses to run on an
installed system and refuses disks with mounted partitions. Everything it
does is also documented manually below.

### Manual steps

1. **Generate an age key** for sops-nix (used for secrets):

   ```bash
   nix run nixpkgs#age -c mkdir -p ~/.config/sops/age
   nix run nixpkgs#age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. **Port our secrets**: copy `secrets/.sops.yaml.example` to
   `secrets/.sops.yaml`, put your public age key in it, then:

   ```bash
   sops secrets/secrets.yaml
   # add e.g.:
   #   my-secret: supersecretvalue
   ```

   Reference the secret in a module (see `modules/features/secrets.nix`
   for the example-wifi secret):

   ```nix
   sops.secrets.my-secret = { };
   # decrypted path: /run/secrets/my-secret
   ```

   > The module reads the age key at `/root/.config/sops/age/keys.txt` on
   > the **installed** system (root's home). setup.sh copies the key there
   > during the installer flow; if you install manually, copy/mount the key
   > into the target's `/root/.config/sops/age/keys.txt` before the first
   > switch — otherwise a new key is generated that doesn't match
   > `secrets/.sops.yaml` and sops activation fails.

3. **Make sure the disk labels exist** for the host's `fileSystems`:

   ```bash
   # format with the expected labels (or set them explicitly):
   mkfs.vfat -F 32 -n nixos-boot /dev/sdX1
   mkfs.xfs -f -L nixos-root   /dev/sdX2
   lsblk -f   # confirm the labels match modules/hosts/*.nix
   ```

4. Rebuild a host:

   ```bash
   sudo nixos-rebuild switch --flake .#nixos-desktop
   # or: make rebuild HOST=nixos-laptop
   ```

5. **Set the user password** (manual fallback — setup.sh does this for
   you): generate a SHA-512 hash and place it on the machine so the config
   picks it up at the next activation:

   ```bash
   openssl passwd -6            # type the password, copy the printed hash
   printf '%s\n' 'PASTE-HASH-HERE' | sudo tee /etc/hashed-password >/dev/null
   sudo chmod 600 /etc/hashed-password
   sudo nixos-rebuild switch --flake .#<host>
   ```

   The file is read on **each** activation via `hashedPasswordFile` (see the
   note under "First-time setup"), so you can also just write it and wait
   for the next rebuild.

### Manual partitioning (fallback)

From the NixOS installer ISO, without setup.sh:

```bash
# wipe the disk and create the GPT layout (sdX -> your disk)
sgdisk --zap-all /dev/sdX
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:nixos-boot /dev/sdX
sgdisk -n 2:0:0  -t 2:8300 -c 2:nixos-root /dev/sdX

# format (nvme/mmcblk: use ${disk}p1 / ${disk}p2 instead of sdX1/sdX2)
mkfs.vfat -F 32 -n nixos-boot /dev/sdX1
mkfs.xfs -f -L nixos-root /dev/sdX2

# mount and install
mount /dev/sdX2 /mnt
mkdir -p /mnt/boot && mount /dev/sdX1 /mnt/boot
nixos-generate-config --root /mnt
# copy the flake into /mnt/etc/nixos, then:
nixos-install --flake /mnt/etc/nixos#nixos-desktop
```

## Day-to-day maintenance

This section covers the everyday and periodic upkeep of an installed host:
updating, rebuilding, rolling back, and cleaning up. Unless noted, run these
**on the machine** and from the **repo directory**.

A `Makefile` wraps the common commands (run `make help` for the full list):

| Command | What it does |
|---------|--------------|
| `make check` | `nix flake check` — builds every host config to catch errors |
| `make fmt-check` | fails if `nix fmt` would change anything |
| `make update` | `nix flake update` — refresh all inputs |
| `make build` / `make rebuild` | build / build+activate the `HOST` (default `nixos-desktop`) |
| `make hooks` | install git hooks (`core.hooksPath` → `.githooks`, once per clone) |
| `make develop` | `nix develop` — formatter + Nix linters (nixpkgs-fmt, deadnix, statix) |

Some cleanup runs automatically already (see `modules/features/optimisation.nix`):

- **`nix.gc.automatic = true`** — weekly `nix-collect-garbage --delete-older-than 7d`
- **`nix.settings.auto-optimise-store = true`** — dedupe store paths
- **`nix.settings.min-free` / `max-free`** — auto-GC when the store drops below 5 GiB free
- **`services.fstrim.enable = true`** — weekly SSD TRIM
- **`systemd.tmpfiles.rules`** — daily cleanup of browser caches, thumbnails, and `/tmp/nix-build-*`
- **`services.journald.extraConfig`** — journal capped at 500 MiB / 30 days

### Regular update (weekly)

The most common task: pull the latest packages, rebuild, and switch to the
new generation.

```bash
git status                    # make sure you have no uncommitted changes
git pull                      # if the repo is shared/pushed
nix flake update              # update nixpkgs, home-manager, sops-nix together
git diff flake.lock           # review what changed before committing/building
nix fmt                       # keep formatting clean
git add flake.nix flake.lock && git commit -m "chore: update flake inputs"
sudo nixos-rebuild switch --flake .#nixos-desktop   # or: make rebuild
systemctl --failed            # confirm nothing broke
```

- Only update a single input: `nix flake update nixpkgs`
  (+ you can lock just one: `nix flake lock --update-input nixpkgs`).
- Home-manager is configured **inside** the flake, so `nixos-rebuild switch`
  updates it too — no separate `home-manager switch` is needed.
- Before pushing, the `pre-push` hook runs `nix fmt --check` + `nix flake check`
  (install once with `make hooks`).

### Rebuild safely (before flipping the switch)

```bash
sudo nixos-rebuild build --flake .#nixos-desktop   # build only, don't activate (make build)
sudo nixos-rebuild boot --flake .#nixos-desktop    # build + set as next boot
sudo nixos-rebuild switch --flake .#nixos-desktop  # build + activate now (make rebuild)
```

- `build` is a harmless dry run for syntax/config errors; `switch` changes the
  running system right away.
- After a rebuild, spot-check: `systemctl --failed`, `journalctl -p 3 -b`.

### Updating just home-manager state

You don't normally do this separately. But if you edit something in
`modules/home/`
and only want to apply the user part on a machine without rebuilding the
system profile (useful for quick experiments):

```bash
nix fmt
sudo nixos-rebuild switch --flake .#nixos-desktop
# or, to test just the user environment:
nix run home-manager/release-26.05 -- switch --flake .
```

### Rolling back

If an update breaks something, there are two ways — the boot-menu is the most
reliable because it works even if modules fail to load:

| Method | When to use | Command |
|--------|-------------|---------|
| Boot menu | system won't boot / you want the old snapshot | restart, pick an older **systemd-boot** entry |
| Rebuild switch | system boots but you want the previous profile | `sudo nixos-rebuild switch --rollback` |
| Older gen | roll back to a specific past generation | `sudo nix-env --profile /nix/var/nix/profiles/system --list-generations` |

- systemd-boot keeps every generation up to
  `boot.loader.systemd-boot.configurationLimit = 24` (see
   `modules/features/hardware/uefi.nix`), and the ESP is masked root-only. To actually
  see the menu at boot, you may want `boot.loader.timeout = 10;` in the host
  file.
- `switch --rollback` activates the previously *active* generation (NOT the
  list of boot entries — the two swap lists can differ), so the menu is the
  source of truth for going "further back".

### Cleaning up (periodic)

Garbage collection is automatic, but you may want to reclaim space manually
or shrink logs:

```bash
sudo nix-collect-garbage -d  # delete all unused paths (incl. old generations)
sudo nix-store --optimise    # dedupe hardlinks (you have auto-optimise on)
sudo du -sh /nix/store        # total store size
sudo ncdu /nix                # interactive: find big /nix paths
journalctl --vacuum-size=1G  # cap the system journal to 1 GB
sudo nixos-rebuild list-generations   # see system generations + how old
```

- `nix-collect-garbage -d` clears *all* old generations, so you lose the
  boot-menu rollback history — keep at least one before it (use `list-generations`
  first).
- To drop only old/broken generations, keep running weekly GC and rely on the
  default `--delete-older-than 7d`.

### Practical schedule

| Frequency | Action |
|-----------|--------|
| Weekly | `nix flake update` → `nixos-rebuild switch` → `systemctl --failed` |
| Monthly | `sudo nix-collect-garbage -d` + `journalctl --vacuum-size=...` |
| After install | verify with `systemctl --failed`, `lsblk -f` (labels match) |

## Notes

- **Boot / snapshots**: systemd-boot lists NixOS generations (up to
   `systemd-boot.configurationLimit` — see `modules/features/hardware/uefi.nix`), so
  opening the boot menu lets you boot a previous system state ("snapshot").
  Every entry carries a kernel+initrd on the ESP (~100MB), so the limit keeps
  the 1 GiB ESP from filling up; GC (`nix.gc.automatic`) prunes old store
  generations in parallel.
- **First login**: the password is whatever you set during setup — the hash
  is stored on the machine at `/etc/hashed-password` (read at activation). If
  it wasn't provisioned (e.g. a fresh clone on a machine that never ran
  ./setup.sh), `mario` has no password until you write the file or run
  `sudo passwd mario`.
- Exact version pinning is handled by `flake.lock`; `nix flake update`
  updates all inputs together. sops-nix and nix-flatpak both follow
  `nixpkgs`, so there is exactly one nixpkgs revision in the lock.
- **Unstable packages**: `nixpkgs-unstable` is a separate input exposed as
  `pkgs.unstable` via an overlay in `flake.nix`. It's used for apps that
  aren't on the stable channel (currently Discord). It gets updated together
  with everything else on `nix flake update`.
- `nix fmt` uses the `#formatter` output (nixpkgs-fmt); `nix develop` drops
  you into a shell with `nixpkgs-fmt`, `deadnix`, and `statix`.
- `nix flake check` builds every host config (`#checks`) — run it before
  rebuilding on a real machine or after structural refactors.
- **SSH access**: on hosts with `mySystem.enableSSH = true` the server rejects
  password logins, so access depends entirely on
  `mySystem.sshAuthorizedKeys` — put your real public keys there or SSH will
  accept no one (a build-time warning reminds you of this).

## Roadmap

- [x] sops-nix real secrets (opt-in via `mySystem.enableSops`)
- [x] simple two-partition XFS layout (impermanence removed)
- [x] local quality gates: `make check`, `make fmt-check`, git hooks, devShell