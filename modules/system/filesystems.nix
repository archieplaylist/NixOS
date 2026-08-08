# Simple two-partition XFS layout: / and /boot, both referenced by
# filesystem label (created by setup.sh's partition step):
#
#   p1: ESP 1 GiB, vfat, label nixos-boot -> /boot
#   p2: root rest  xfs,  label nixos-root -> /
#
# No /nix or /persist mounts needed — the nix store lives on the root
# filesystem and all state (home dirs, /var, /etc) is inherently persistent.
{ config, lib, ... }: {
  boot.initrd.supportedFilesystems = [ "xfs" ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos-root";
      fsType = "xfs";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/nixos-boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };
}