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
    ../modules/hardware/vm-guest.nix
  ];

  # --- Host identity -----------------------------------------------------
  # NixOS guest intended to run inside a VM (VirtualBox or virt-manager).
  mySystem.hostname = "nixvms";
  mySystem.enableDesktop = true;
  mySystem.enableSSH = true;
  mySystem.enableDocker = false;
  mySystem.enableTailscale = false;
  mySystem.enableSops = false;

  # --- Users -------------------------------------------------------------
  users.users.mario = {
    isNormalUser = true;
    description = "Mario";
    extraGroups = [ "wheel" "video" "audio" ];
    initialPassword = lib.mkDefault "changeme";
  };

  # --- Boot / filesystems -----------------------------------------------
  # EFI UEFI image to boot VirtualBox/QEMU.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };

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

  boot.initrd.supportedFilesystems = [ "xfs" ];

  # --- Misc --------------------------------------------------------------
  # Allow the wheel group to run sudo without/with a password.
  security.sudo.wheelNeedsPassword = lib.mkDefault true;
}