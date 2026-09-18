# desktop — gnome + intel/uefi, gaming performance governor
{ config, lib, ... }: {
  config.nixos.hosts.desktop = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
    ];

    mySystem.hostname = "nixdesks";
    mySystem.desktop = "gnome";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = true;
    mySystem.enableDocker = true;
    mySystem.enableTailscale = true;
    mySystem.enableSmartd = true;
    mySystem.enableSunshine = true;
    mySystem.enableMoonlight = true;

    mySystem.appGroups.browsers.enable = true;
    mySystem.appGroups.media.enable = true;
    mySystem.appGroups.office.enable = true;
    mySystem.appGroups.editor.enable = true;
    mySystem.appGroups.gaming.enable = true;
    mySystem.appGroups.ai.enable = true;

    mySystem.flatpakApps = lib.mkAfter [ "com.mattjakeman.ExtensionManager" ];
  };
}
