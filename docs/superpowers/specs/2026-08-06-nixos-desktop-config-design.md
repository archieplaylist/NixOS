# NixOS Desktop Config Design

Date: 2026-08-06
Status: Approved

## Purpose

A complete, well-structured NixOS configuration for a desktop workstation
targeting NixOS 24.11, built as a flake with modular system modules, per-host
configs, home-manager user config, and sops-nix secret handling. Must serve
as a template the user can customize later and deploy to both a desktop and a
laptop machine.

## Requirements

- Flake-based, pinned to nixpkgs release-24.11 (stable)
- Home-manager (release-24.11) for user-level configuration
- GNOME desktop on Wayland, GDM display manager
- Intel iGPU with open drivers and VA-API hardware acceleration
- UEFI boot with systemd-boot; boot entries per NixOS generation act as the
  "snapshot" boot mechanism
- Root filesystem: XFS (per user request)
- User `mario`, hostname `nixos-desktop`, locale `en_US.UTF-8`
- Packages: VS Code, git/gh, docker/podman, Firefox, media codecs,
  development toolchains (Python, Node, Go, Rust), direnv
- Services: openssh (hardened), docker, tailscale, flatpak
- Secrets via sops-nix with age keys; placeholder structure only
- Support both desktop and laptop hardware (laptop power management is an
  opt-in module)

## Architecture

```
NixOS/
├── flake.nix               # inputs: nixpkgs, home-manager, sops-nix
├── flake.lock
├── modules/
│   ├── system/basics.nix   # networking, nix settings, fonts, stateVersion
│   ├── system/desktop.nix  # GNOME, GDM, Wayland, PipeWire, NetworkManager
│   ├── hardware/intel.nix  # Intel iGPU, microcode, VA-API
│   ├── hardware/uefi.nix   # systemd-boot, EFI, XFS root
│   ├── hardware/laptop.nix # power management, backlight, lid close
│   └── services.nix        # ssh, docker, tailscale, flatpak
├── hosts/
│   ├── nixos-desktop.nix   # desktop host: imports + users + filesystems
│   └── nixos-laptop.nix    # laptop host: + laptop.nix module
├── home/
│   ├── default.nix         # core home-manager config
│   └── mario.nix           # user mario: packages, dotfiles, shell
├── secrets/                # sops-nix placeholders + example
├── docs/superpowers/specs/ # this spec
└── README.md               # deployment instructions
```

## Key Decisions

- **systemd-boot over GRUB**: automatically lists every NixOS generation as a
  boot entry, providing boot-a-previous-state capability on XFS without
  btrfs snapshots
- **XFS root filesystem** with separate vfat EFI boot partition; mount
  definitions live in host files since device UUIDs are machine-specific
- **Per-host modules**: hardware and power modules are opt-in imports so
  desktop and laptop hosts share the common core
- **sops-nix** for secrets: `.sops.yaml` + `secrets.yaml`, encrypted with an
  age key the user generates; `.example` placeholders committed so the flake
  evaluates before keys exist
- **home-manager** with `useGlobalPkgs` + `useUserPackages` for user-level
  packages and declarative dotfiles

## Non-Goals

- Real secrets content (user generates age keys and populates)
- Actual disk partition/UUID values (machine-specific, documented in README)
- btrfs subvolume snapshots (XFS chosen; generation boot covers rollback)
- Deployment itself (target machines not available; README documents steps)

## Verification

- `nix flake check` on a NixOS machine
- `nix fmt` / nixpkgs-fmt formatting pass
- README documents partitioning, age key, and rebuild commands

## Deployment Notes

Config is a template: user must set real disk UUIDs in host files, generate
an age key, run `sops` to create `secrets.yaml`, then
`nixos-rebuild switch --flake .#nixos-desktop`.
