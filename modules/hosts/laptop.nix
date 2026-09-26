# laptop — plasma + power-management
{ config, ... }: {
  config.nixos.hosts.laptop = { pkgs, ... }: {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
      config.nixos.modules.laptop
    ];

    # latest kernel for newer laptop hardware — drop when stable suffices
    boot.kernelPackages = pkgs.linuxPackages_latest;

    mySystem.hostname = "nixlappys";
    mySystem.desktop = "plasma";
    mySystem.enableDesktop = true;
    mySystem.enableLaptop = true;
    mySystem.enableTailscale = true;
    mySystem.enableSmartd = true;
    mySystem.enableSunshine = true;
    mySystem.enableMoonlight = true;

    mySystem.appGroups.browsers.enable = true;
    mySystem.appGroups.media.enable = true;
    mySystem.appGroups.office.enable = true;
    mySystem.appGroups.comms.enable = true;
    mySystem.appGroups.editor.enable = true;
    mySystem.appGroups.gaming.enable = true;
    mySystem.appGroups.ai.enable = true;
  };
}
