# laptop — xfce + power-management, no dev packages
{ config, ... }: {
  config.nixos.hosts.laptop = { pkgs, ... }: {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
      config.nixos.modules.laptop
    ];

    boot.kernelPackages = pkgs.linuxPackages_latest;

    mySystem.hostname = "nixlappys";
    mySystem.desktop = "gnome";
    mySystem.enableDesktop = true;
    mySystem.enableLaptop = true;
    mySystem.enableLuks = true; # fresh install only — requires repartition with setup.sh --luks --tpm2
    mySystem.enableTpm2 = true; # TPM2 auto-unlock, passphrase fallback
    mySystem.enableSecureBoot = false; # flip to true after `sbctl create-keys && sbctl enroll-keys --microsoft` on first boot
    mySystem.enableSSH = false;
    mySystem.enableDocker = false;
    mySystem.enableTailscale = true;
    mySystem.enableSops = true;
    mySystem.enableSmartd = true;

    mySystem.sshAuthorizedKeys = [ ];
    mySystem.appGroups.dev.enable = false;
  };
}
