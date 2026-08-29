# UEFI boot — systemd-boot (default) or lanzaboote (Secure Boot, 1s timeout, 10 generations)
{ ... }: {
  config.nixos.modules.uefi = { config, lib, ... }: {
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
    boot.loader.timeout = 1;

    # systemd-boot unless Secure Boot is enabled (lanzaboote replaces it)
    boot.loader.systemd-boot.enable = !config.mySystem.enableSecureBoot;
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

    boot.lanzaboote.enable = config.mySystem.enableSecureBoot;
    boot.lanzaboote.pkiBundle = "/var/lib/sbctl";
    boot.lanzaboote.configurationLimit = 10;
  };
}
