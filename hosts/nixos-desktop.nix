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
  ];

  # --- Host identity -----------------------------------------------------
  mySystem.hostname = "nixos-desktop";
  mySystem.enableDesktop = true;
  mySystem.enableSSH = true;
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
      device = "/dev/disk/by-uuid/12345678-1234-1234-1234-1234567890ab";
      fsType = "xfs";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/12345678-1234-1234-1234-1234567890ab";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  # Default boot device (UEFI).
  boot.loader.efi.efiSysMountPoint = "/boot";

  # --- Misc --------------------------------------------------------------
  # Allow the wheel group to run sudo without a password.
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
}
