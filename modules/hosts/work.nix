# work — gnome + virtualbox host + work flatpaks
{ config, lib, ... }: {
  config.nixos.hosts.work = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
    ];

    mySystem.hostname = "nixworks";
    mySystem.desktop = "gnome";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = true;
    mySystem.enableDocker = true;
    mySystem.enableTailscale = false;
    mySystem.enableSops = true;
    mySystem.enableVirtualBox = true;
    mySystem.enableSmartd = true;

    mySystem.sshAuthorizedKeys = [ ];
    mySystem.appGroups.work.enable = true;
    mySystem.appGroups.gaming.enable = false;

    mySystem.flatpakApps = lib.mkAfter [
      "rest.insomnia.Insomnia"
      "com.mattjakeman.ExtensionManager"
    ];
  };
}
