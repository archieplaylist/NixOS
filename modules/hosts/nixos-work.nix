# nixos-work host: workstation — same as the desktop host but without
# Tailscale, plus a VirtualBox host, work apps (dbeaver, filezilla, remmina)
# and the declarative Flatpak apps below.
{ config, ... }: {
  config.nixos.hosts.nixos-work = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
    ];

    mySystem.hostname = "nixworks";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = true;
    mySystem.enableDocker = true;
    mySystem.enableTailscale = false;
    mySystem.enableSops = true;
    mySystem.enableVirtualBox = true;

    # SSH password auth is disabled (see services.nix), so the keys below are
    # what actually grants access — add your real public keys here.
    mySystem.sshAuthorizedKeys = [ ];

    # Work apps live in home-manager (dbeaver-bin, filezilla, remmina).
    mySystem.appGroups.work.enable = true;

    # Workstation: no gaming packages (Steam, MangoHud, gamescope, Heroic).
    mySystem.appGroups.gaming.enable = false;

    # Declarative Flatpak apps (nix-flatpak; daemon + wiring live in desktop.nix,
    # flathub remote is added by the module by default).
    mySystem.flatpakApps = [
      "com.github.wwmm.easyeffects"
      "rest.insomnia.Insomnia"
      "org.localsend.localsend_app"
      "it.mijorus.gearlever"
      "com.github.tchx84.Flatseal"
      "com.mattjakeman.ExtensionManager"
    ];
  };
}
