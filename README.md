# NixOS Desktop Configuration

A modular, flake-based NixOS configuration for Mario's workstations
(NixOS 24.11, GNOME, Intel). Supports both a desktop and a laptop host.

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

The quickest way is the setup script (interactive, idempotent, non-destructive):

```bash
./setup.sh          # interactive
./setup.sh --yes    # answer yes to everything
```

It will:
1. check the repo layout and required tools,
2. create a sops age key and `secrets/.sops.yaml` from the example,
3. create an encrypted (empty) `secrets/secrets.yaml`,
4. detect your real `/` and `/boot` disk UUIDs and fill them into
   `hosts/*.nix`, and
5. let you pick a host and run `nixos-rebuild switch`.

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
- **First login**: password is `changeme` (change it with `passwd`).
- Exact version pinning is handled by `flake.lock`; `nix flake update`
  updates all inputs together.
- `nix fmt` uses the `#formatter` output (nixpkgs-fmt).

## Roadmap

- [ ] sops-nix real secrets
- [ ] impermanence (optional, opt-in)