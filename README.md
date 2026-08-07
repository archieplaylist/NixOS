# NixOS Desktop Configuration

A modular, flake-based NixOS configuration for Mario's workstations
(NixOS 26.05, GNOME, Intel). Supports both a desktop and a laptop host.

## Layout

```
├── flake.nix            # inputs + host definitions
├── modules/
│   ├── system/          # basics, desktop (GNOME), services
│   └── hardware/        # intel, uefi (systemd-boot + XFS), laptop
├── hosts/               # per-machine host files
├── home/                # home-manager user config (mario)
├── secrets/             # sops-nix placeholders
└── docs/                # design spec
```

## Adding a host

1. Copy `hosts/nixos-desktop.nix` to `hosts/new-host.nix`.
2. Add a `nixosConfigurations.new-host = buildHost "new-host";` line in
   `flake.nix`.
3. Set `mySystem.hostname` (filesystems are referenced by label — see the
   partition step below).

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
3. **set the user password**: hashed (SHA-512) and written as
   `hashedPassword` into `hosts/*.nix`,
4. create a sops age key and `secrets/.sops.yaml` from the example,
5. create an encrypted (empty) `secrets/secrets.yaml`, and
6. let you pick a host and run `nixos-rebuild switch`.

Filesystems are referenced by **label** (`/dev/disk/by-label/nixos-root` for
`/`, `/dev/disk/by-label/nixos-boot` for `/boot`), which the partition step
creates — no UUID detection needed.

> **Note on the password**: the SHA-512 hash is stored in the git-tracked
> host files. Keep this repo private; to change the password later, run
> `passwd` on the machine or update the hash with
> `openssl passwd -6` (see below).

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
   you): generate a SHA-512 hash and put it into `hashedPassword` in the
   host file, replacing `initialPassword`:

   ```bash
   openssl passwd -6
   # in hosts/nixos-desktop.nix:
   #   hashedPassword = lib.mkDefault "$6$...";   # instead of initialPassword
   ```

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
- **First login**: the password is whatever you set during setup
  (`hashedPassword`). Fresh clones without a hash fall back to `changeme`.
- Exact version pinning is handled by `flake.lock`; `nix flake update`
  updates all inputs together.
- `nix fmt` uses the `#formatter` output (nixpkgs-fmt).
- **Impermanence**: opt-in per host with `mySystem.enableImpermanence = true;`.
  It works on XFS — instead of btrfs subvolumes it keeps a persistent
  `/persist` and wipes everything else on every boot. Files/dirs to keep are
  listed in `modules/system/impermanence.nix`.

## Roadmap

- [x] sops-nix real secrets (opt-in via `mySystem.enableSops`)
- [x] impermanence (optional, opt-in via `mySystem.enableImpermanence`)