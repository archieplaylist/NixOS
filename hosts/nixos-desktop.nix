{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ../modules/system/basics.nix
    ../modules/system/desktop.nix
    ../modules/system/services.nix
    ../modules/system/secrets.nix
    ../modules/hardware/intel.nix
    ../modules/hardware/uefi.nix
  ];

  # --- Host identity -----------------------------------------------------
  mySystem.hostname = "nixdesks";
  mySystem.enableDesktop = true;
  mySystem.enableSSH = true;
  mySystem.enableDocker = true;
  mySystem.enableTailscale = true;
  mySystem.enableSops = true;

  # --- Users -------------------------------------------------------------
  users.users.mario = {
    isNormalUser = true;
    description = "Mario";
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" ];
    openssh.authorizedKeys.keys = lib.mkDefault [ ];
    initialPassword = lib.mkDefault "changeme";
  };

  # --- Boot / filesystems -----------------------------------------------
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

  # Default boot device (UEFI).
  boot.loader.efi.efiSysMountPoint = "/boot";

  # --- Misc --------------------------------------------------------------
  # Allow the wheel group to run sudo without/with a password.
  security.sudo.wheelNeedsPassword = lib.mkDefault true;
}
