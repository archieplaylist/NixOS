{ ...
}: {
  # systemd-boot: every NixOS generation becomes a boot entry,
  # i.e. boot a previous system state ("snapshot") from the menu.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Keep the most recent generations so rollback entries remain available
  # without letting the 1 GiB ESP fill up (each entry carries kernel+initrd,
  # ~100MB per generation with weekly updates).
  boot.loader.systemd-boot.configurationLimit = 24;
}