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
  mySystem.hostname = "nixdesks";
  mySystem.enableDesktop = true;
  mySystem.enableSSH = true;
  mySystem.enableDocker = true;
  mySystem.enableTailscale = true;
  mySystem.enableSops = true;

  # Declarative Flatpak apps (nix-flatpak; daemon + wiring live in desktop.nix).
  mySystem.flatpakApps = [
    "io.missioncenter.MissionCenter"
    "com.github.wwmm.easyeffects"
    "org.localsend.localsend_app"
    "it.mijorus.gearlever"
    "com.github.tchx84.Flatseal"
    "com.mattjakeman.ExtensionManager"
  ];

  # SSH password auth is disabled (see services.nix), so the keys below are
  # what actually grants access — add your real public keys here.
  mySystem.sshAuthorizedKeys = [ ];
}