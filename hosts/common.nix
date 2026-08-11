# Baseline imports shared by every host. Host-specific files add
# `./common.nix` plus only their deltas (desktop.nix, hardware extras).
{ ...
}: {
  imports = [
    ../modules/system/basics.nix
    ../modules/system/services.nix
    ../modules/system/secrets.nix
    ../modules/system/users.nix
    ../modules/system/filesystems.nix
    ../modules/hardware/uefi.nix
  ];
}