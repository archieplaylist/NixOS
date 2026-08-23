# Two-partition XFS layout: / (nixos-root) + /boot (nixos-boot, vfat)
{ ... }: {
  config.nixos.modules.base = {
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
  };
}
