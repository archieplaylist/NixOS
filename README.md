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
3. Set `mySystem.hostname` and the real disk UUIDs (step below).

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
5. create an encrypted (empty) `secrets/secrets.yaml`,
6. detect your real `/` and `/boot` disk UUIDs and fill them into
   `hosts/*.nix`, and
7. let you pick a host and run `nixos-rebuild switch`.

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

3. **Fill in your real disk UUIDs** in the host file(s):

   ```bash
   lsblk -f
   # replace the two placeholders under fileSystems with your / and /boot UUIDs
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

## Day-to-day

```bash
nix flake update            # update inputs (nixpkgs, home-manager, sops-nix)
nix flake lock              # freeze / commit flake.lock
nix fmt                      # format all .nix files (uses treefmt)
nixos-rebuild switch --flake .#nixos-desktop   # after edits
```

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