# UEFI systemd-boot (1s timeout, 10 generations)
{ ... }: {
  config.nixos.modules.uefi = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
    boot.loader.timeout = 1;
    boot.loader.systemd-boot.configurationLimit = 10;
  };
}
