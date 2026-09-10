# laptop — gnome + power-management, no dev packages
{ config, ... }: {
  config.nixos.hosts.laptop = { pkgs, ... }: {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
      config.nixos.modules.laptop
    ];

    # ponytail: latest kernel for newer laptop hardware — drop when stable suffices
    boot.kernelPackages = pkgs.linuxPackages_latest;

    mySystem.hostname = "nixlappys";
    mySystem.desktop = "gnome";
    mySystem.enableDesktop = true;
    mySystem.enableLaptop = true;
    mySystem.enableTailscale = true;
    mySystem.enableSmartd = true;

    mySystem.appGroups.dev.enable = false;
    mySystem.appGroups.work.enable = false;
  };
}
