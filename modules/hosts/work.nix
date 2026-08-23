# work host: workstation — same as the desktop host but without
# Tailscale, plus a VirtualBox host, work apps (dbeaver, filezilla, remmina)
# and the declarative Flatpak apps below.
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

    # SSH password auth is disabled (see services.nix), so the keys below are
    # what actually grants access — add your real public keys here.
    mySystem.sshAuthorizedKeys = [ ];

    # Work apps live in home-manager (dbeaver-bin, filezilla, remmina).
    mySystem.appGroups.work.enable = true;

    # Workstation: no gaming packages (Steam, MangoHud, gamescope, Heroic).
    mySystem.appGroups.gaming.enable = false;

    # +Insomnia + Extension Manager on top of the base Flatpaks (mySystem.nix).
    mySystem.flatpakApps = lib.mkAfter [
      "rest.insomnia.Insomnia"
      "com.mattjakeman.ExtensionManager"
    ];
  };
}
