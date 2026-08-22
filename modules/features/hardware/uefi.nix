# UEFI boot with systemd-boot: every NixOS generation becomes a boot entry,
# i.e. boot a previous system state ("snapshot") from the menu.
# Contributes a NixOS module to the `uefi` slot.
{ ... }: {
  config.nixos.modules.uefi = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # Don't idle at the boot menu; it stays reachable every boot for picking
    # older generations (rollbacks).
    boot.loader.timeout = 1;

    # Parallelized systemd early userspace — faster than the script initrd
    # (measured ~3.5s initrd phase on the slowest host).
    boot.initrd.systemd.enable = true;

    # Explicit zstd: best speed/ratio tradeoff for the ~55MB initrd image.
    boot.initrd.compressor = "zstd";

    # Keep rollback entries available without letting the 1 GiB ESP fill up
    # (each entry carries kernel+initrd, ~70MB per generation → ~10 max fit;
    # a full ESP makes nixos-rebuild fail during bootloader install).
    boot.loader.systemd-boot.configurationLimit = 10;
  };
}
