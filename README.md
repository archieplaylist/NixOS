# NixOS Desktop Configuration

A modular, flake-based NixOS configuration for Mario's workstations
(NixOS 26.05, GNOME, Intel). Supports both a desktop and a laptop host.

## Layout

├── flake.nix            # inputs + host definitions
├── modules/
│   ├── system/          # options, basics, desktop (GNOME), services, secrets,
│   │                    # users, filesystems, impermanence (not-ready)
│   └── hardware/        # intel, uefi (systemd-boot + XFS), laptop, vm-guest
├── hosts/               # per-machine host files (imports + mySystem flags)
├── home/                # home-manager user config (mario)
└── secrets/             # sops-nix placeholders
```

## Adding a host

Host files are thin: they only pick imports and set `mySystem` flags. The
user account, filesystems (label-based mounts), and all option definitions
live in shared modules (`modules/system/options.nix`, `users.nix`,
`filesystems.nix`).

1. Copy `hosts/nixos-desktop.nix` to `hosts/new-host.nix`.
2. Add a `nixosConfigurations.new-host = buildHost "new-host";` line in
   `flake.nix`.
3. Set `mySystem.hostname` (filesystems are referenced by label — see the
   partition step below).
4. Optionally disable general-purpose applications on this host with
   `home-manager.users.mario.myApps.enable = false;`.

## General-purpose applications

Enabled by default on every desktop host (controllable per host via
`home-manager.users.mario.myApps.enable`):

- **Browsers:** Firefox, Chromium, Vivaldi
- **Multimedia:** VLC, mpv
- **Gaming:** Heroic Games Launcher, MangoHud, gamescope; Steam + 32-bit
  OpenGL multilib are set up at the system level (`modules/system/desktop.nix`)

The browser/media/gaming user packages live in `home/mario.nix` (via
home-manager), gated behind the same flag.

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
> `users.users.mario.hashedPasswordFile` (`modules/system/users.nix`). It
> never lives in the repo, so there is no git interaction and nothing for a
> fresh clone to leak. The hash path itself is always set in the config; if
> the file is missing on a machine, activation only warns and `mario` has no
> password until one is provisioned. To change it later, re-run `./setup.sh`
> or run `sudo passwd mario` on the machine.

Partitioning creates this layout on the selected disk (GPT):

```
/dev/sdX
├── 1: ESP  1 GiB  vfat (label nixos-boot)
└── 2: root  rest  xfs  (label nixos-root)
```

Swap is handled with zram (`zramSwap.enable`), so no swap partition is
needed. The partition step refuses to run on an installed system and
refuses disks with mounted partitions — it is meant to be run from the
NixOS installer ISO, which is exactly where it auto-detects.

Everything it does is also documented step by step below, if you prefer to
do it manually.

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

   Reference the secret in a module (see `modules/system/secrets.nix`
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
   lsblk -f   # confirm the labels match hosts/*.nix
   ```

4. Rebuild a host:

   ```bash
   nixos-rebuild switch --flake .#nixos-desktop
   nixos-rebuild switch --flake .#nixos-laptop
   ```

5. **Set the user password** (manual fallback — setup.sh does this for
   you): generate a SHA-512 hash and place it on the machine so the config
   picks it up at the next activation:

   ```bash
   openssl passwd -6            # type the password, copy the printed hash
   printf '%s\n' 'PASTE-HASH-HERE' | sudo tee /etc/hashed-password >/dev/null
   sudo chmod 600 /etc/hashed-password
   # then rebuild for it to take effect:
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
**on the machine** and from the **repo directory** (`~/Documents/.../NixOS`).

Some cleanup runs automatically already (see `modules/system/basics.nix`):

- **`nix.gc.automatic = true`** — weekly `nix-collect-garbage
  --delete-older-than 14d`
- **`nix.settings.auto-optimise-store = true`** — dedupe store paths
- **`services.fstrim.enable = true`** — weekly SSD TRIM

### Regular update (weekly)

The most common task: pull the latest packages, rebuild, and switch to the
new generation.

```bash
git status                 # make sure you have no uncommitted changes
git pull                   # if the repo is shared/pushed
nix flake update           # update nixpkgs, home-manager, sops-nix together
git diff flake.lock        # review what changed before committing/building
nix fmt                     # keep formatting clean
git add flake.nix flake.lock && git commit -m "chore: update flake inputs"
sudo nixos-rebuild switch --flake .#nixos-desktop
systemctl --failed         # confirm nothing broke
```

- Only update a single input: `nix flake update nixpkgs`
  (+ you can lock just one: `nix flake lock --update-input nixpkgs`).
- Home-manager is configured **inside** the flake, so `nixos-rebuild switch`
  updates it too — no separate `home-manager switch` is needed.

### Rebuild safely (before flipping the switch)

```bash
sudo nixos-rebuild build --flake .#nixos-desktop   # build only, don't activate
sudo nixos-rebuild boot --flake .#nixos-desktop    # build + set as next boot
sudo nixos-rebuild switch --flake .#nixos-desktop  # build + activate now
```

- `build` is a harmless dry run for syntax/config errors; `switch` changes the
  running system right away.
- After a rebuild, spot-check: `systemctl --failed`, `journalctl -p 3 -b`.

### Updating just home-manager state

You don't normally do this separately. But if you edit `home/mario.nix` and
only want to apply the user part on a machine without rebuilding the system
profile (useful for quick experiments):

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

- systemd-boot keeps every generation (see the **Notes** section above). To
  actually see the menu at boot, you may want
  `boot.loader.timeout = 10;` in the host file.
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
  default `--delete-older-than 14d`.

### Practical schedule

| Frequency | Action |
|-----------|--------|
| Weekly | `nix flake update` → `nixos-rebuild switch` → `systemctl --failed` |
| Monthly | `sudo nix-collect-garbage -d` + `journalctl --vacuum-size=...` |
| After install | verify with `systemctl --failed`, `lsblk -f` (labels match) |

## Notes

- **Boot / snapshots**: systemd-boot lists every NixOS generation, so opening
  the boot menu lets you boot a previous system state ("snapshot"). For real
  filesystem snapshots you'd need btrfs instead of XFS.
- **First login**: the password is whatever you set during setup — the hash
  is written to `/etc/hashed-password` on the machine (read at activation).
  If it wasn't provisioned (e.g. a fresh clone on a machine that never ran
  ./setup.sh), `mario` has no password until you write the file or run
  `sudo passwd mario`.
- Exact version pinning is handled by `flake.lock`; `nix flake update`
  updates all inputs together.
- `nix fmt` uses the `#formatter` output (nixpkgs-fmt).
- **Impermanence**: opt-in per host with `mySystem.enableImpermanence = true;`,
  but **not yet functional** — treat it as a design sketch. The XFS label-root
  layout has no `/persist` mount and no tmpfs root, so nothing is actually
  wiped or persisted on boot. Making it real (tmpfs root plus a `/persist`
  partition) is future work; do not enable it expecting stateless behavior.
- **SSH access**: on hosts with `mySystem.enableSSH = true` the server rejects
  password logins, so access depends entirely on
  `mySystem.sshAuthorizedKeys` — put your real public keys there or SSH will
  accept no one (a build-time warning reminds you of this).

## Roadmap

- [x] sops-nix real secrets (opt-in via `mySystem.enableSops`)
- [ ] impermanence (opt-in via `mySystem.enableImpermanence`; currently a
      not-ready design sketch)