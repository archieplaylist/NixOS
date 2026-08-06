{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ../modules/system/basics.nix
    ../modules/system/desktop.nix
    ../modules/system/services.nix
    ../modules/hardware/intel.nix
    ../modules/hardware/uefi.nix
    ../modules/hardware/laptop.nix
  ];

  # --- Host identity -----------------------------------------------------
  mySystem.hostname = "nixos-laptop";
  mySystem.enableDesktop = true;
  mySystem.enableLaptop = true;
  mySystem.enableSSH = false;
  mySystem.enableDocker = true;
  mySystem.enableTailscale = true;

  # --- Users -------------------------------------------------------------
  users.users.mario = {
    isNormalUser = true;
    description = "Mario";
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" ];
    openssh.authorizedKeys.keys = lib.mkDefault [ ];
    initialPassword = lib.mkDefault "changeme";
  };

  # --- Boot / filesystems -----------------------------------------------
  # IMPORTANT: replace the UUIDs below with the actual UUIDs of your disks
  # (lsblk -f). /boot must be vfat, / must be xfs.
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
      fsType = "xfs";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/0000-0000";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  boot.loader.efi.efiSysMountPoint = "/boot";

  # --- Misc --------------------------------------------------------------
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
}
