{ ...
}: {
  # systemd-boot: every NixOS generation becomes a boot entry,
  # i.e. boot a previous system state ("snapshot") from the menu.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Keep all generations so rollback entries remain available.
  boot.loader.systemd-boot.configurationLimit = 0;
}