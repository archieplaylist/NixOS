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
    mySystem.enableSSH = false;
    mySystem.enableDocker = false;
    mySystem.enableTailscale = true;
    mySystem.enableSops = true;
    mySystem.enableSmartd = true;
    
    mySystem.enableLuks = false;
    mySystem.enableSecureBoot = false;
    mySystem.enableTpm2 = false;

    mySystem.appGroups.dev.enable = false;
    mySystem.appGroups.work.enable = false;

    mySystem.sshAuthorizedKeys = [ ];
  };
}
