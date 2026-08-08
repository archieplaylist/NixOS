{ ... }: {
  # Filesystems are referenced by label (not UUID). The setup.sh partition
  # step creates these labels; /boot must be vfat, / must be xfs.
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

  # Support XFS root filesystems in the initrd.
  boot.initrd.supportedFilesystems = [ "xfs" ];
}