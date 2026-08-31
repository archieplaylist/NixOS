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
    mySystem.enableSops = true;
    mySystem.enableSmartd = true;
    
    mySystem.enableLuks = false;
    mySystem.enableTpm2 = false;
    mySystem.enableSecureBoot = false;

    mySystem.appGroups.comms.enable = false;
    mySystem.appGroups.dev.enable = false;
    mySystem.appGroups.work.enable = false;

    powerManagement.cpuFreqGovernor = "performance";

    mySystem.flatpakApps = lib.mkAfter [ "com.mattjakeman.ExtensionManager" ];
    mySystem.sshAuthorizedKeys = [ ];
  };
}
