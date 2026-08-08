# Two supported layouts, selected per host via `mySystem.enableImpermanence`:
#
#  * XFS (default, current installs): single /dev/disk/by-label/nixos-root
#    partition, no /nix or /persist mount.
#  * btrfs (enableImpermanence = true, fresh installs): the same partition is
#    formatted btrfs with three subvolumes — root, nix, persist — mounted at
#    /, /nix and /persist respectively. `/nix` and `/persist` must be mounted
#    in the initramfs (neededForBoot) because activation runs before the normal
#    fileSystems phase.
{ config, lib, ... }: let
  ephem = config.mySystem.enableImpermanence;
in {
  # Filesystems are referenced by label (not UUID). The setup.sh partition
  # step creates these labels; /boot must be vfat.
  boot.initrd.supportedFilesystems = [ (if ephem then "btrfs" else "xfs") ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos-root";
      fsType = if ephem then "btrfs" else "xfs";
      options = lib.optionals ephem [ "subvol=root" ] ++ [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/nixos-boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  } // lib.optionalAttrs ephem {
    "/nix" = {
      device = "/dev/disk/by-label/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" ];
      neededForBoot = true;
    };
    "/persist" = {
      device = "/dev/disk/by-label/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=persist" "noatime" ];
      neededForBoot = true;
    };
  };
}