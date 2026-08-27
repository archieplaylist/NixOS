# work — gnome + virtualbox host + work flatpaks
{ config, lib, ... }: {
  config.nixos.hosts.work = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
    ];

    mySystem.hostname = "central8";
    mySystem.desktop = "gnome";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = false; # ponytail: no authorizedKeys yet — set true + add key after `ssh-keygen -t ed25519` on client
    mySystem.enableDocker = true;
    mySystem.enableTailscale = false;
    mySystem.enableSops = true;
    mySystem.enableVirtualBox = true;
    mySystem.enableSmartd = true;

    mySystem.sshAuthorizedKeys = [
      # "ssh-ed25519 AAAAC3... mario@client" # ponytail: add client pubkey here, then set enableSSH=true
    ];
    mySystem.appGroups.work.enable = true;
    mySystem.appGroups.gaming.enable = false;

    mySystem.flatpakApps = lib.mkAfter [
      "rest.insomnia.Insomnia"
      "com.mattjakeman.ExtensionManager"
    ];
  };
}
