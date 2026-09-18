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
    mySystem.enableDocker = true;
    mySystem.enableTailscale = true; # daemon on for `stream` toggle; `tailscale down` persists across reboots
    mySystem.enableVirtualBox = true;
    mySystem.enableSmartd = true;
    mySystem.enableSunshine = true;
    mySystem.enableMoonlight = true;

    mySystem.sshAuthorizedKeys = [
      # "ssh-ed25519 AAAAC3... user@client" # add client pubkey here, then set enableSSH=true
    ];
    mySystem.appGroups.browsers.enable = true;
    mySystem.appGroups.media.enable = true;
    mySystem.appGroups.office.enable = true;
    mySystem.appGroups.editor.enable = true;
    mySystem.appGroups.dev.enable = true;
    mySystem.appGroups.ai.enable = true;
    mySystem.appGroups.work.enable = true;

    # base firewall already denies incoming; just punch HTTP
    networking.firewall.allowedTCPPorts = [ 80 ];

    mySystem.flatpakApps = lib.mkAfter [
      "rest.insomnia.Insomnia"
      "com.mattjakeman.ExtensionManager"
    ];

    # declarative mount beats raw /etc/fstab — systemd generates mount unit, no extra file
    fileSystems."/mnt/datafile" = {
      device = "/dev/disk/by-uuid/869a1e56-4705-4b2b-a840-2e769b39f962";
      fsType = "ext4";
      options = [ "defaults" "nofail" "x-systemd.device-timeout=5s" ];
    };
  };
}
