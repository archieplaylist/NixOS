{ ...
}: {
  imports = [
    ../modules/system/basics.nix
    ../modules/system/desktop.nix
    ../modules/system/services.nix
    ../modules/system/secrets.nix
    ../modules/system/users.nix
    ../modules/system/filesystems.nix
    ../modules/hardware/intel.nix
    ../modules/hardware/uefi.nix
  ];

  # --- Host identity -----------------------------------------------------
  # Workstation: same as the desktop host but without Tailscale, plus a
  # VirtualBox host, work apps (dbeaver, filezilla, remmina) and the
  # declarative Flatpak apps below.
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
  home-manager.users.mario.myApps.work.enable = true;

  # Declarative Flatpak apps (nix-flatpak; daemon + wiring live in desktop.nix,
  # flathub remote is added by the module by default).
  mySystem.flatpakApps = [
    "io.missioncenter.MissionCenter"
    "com.github.wwmm.easyeffects"
    "rest.insomnia.Insomnia"
    "org.localsend.localsend_app"
    "it.mijorus.gearlever"
    "com.github.tchx84.Flatseal"
    "com.mattjakeman.ExtensionManager"
  ];
}