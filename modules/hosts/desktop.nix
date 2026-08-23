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

    powerManagement.cpuFreqGovernor = "performance";

    mySystem.flatpakApps = lib.mkAfter [ "com.mattjakeman.ExtensionManager" ];
    mySystem.sshAuthorizedKeys = [ ];
  };
}
