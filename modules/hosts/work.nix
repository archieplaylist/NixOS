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
    mySystem.enableSunshine = true; # unit installed but not autostarted — `stream on` starts it
    mySystem.enableMoonlight = true;

    # sunshine streams only over tailscale: no autostart, `stream` script controls it
    systemd.user.services.sunshine.wantedBy = lib.mkForce [ ];

    mySystem.sshAuthorizedKeys = [
      # "ssh-ed25519 AAAAC3... mario@client" # add client pubkey here, then set enableSSH=true
    ];
    mySystem.appGroups.work.enable = true;
    mySystem.appGroups.gaming.enable = false;
    mySystem.appGroups.comms.enable = false;

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
