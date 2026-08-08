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
    ../modules/hardware/laptop.nix
  ];

  # --- Host identity -----------------------------------------------------
  mySystem.hostname = "nixlappys";
  mySystem.enableDesktop = true;
  mySystem.enableLaptop = true;
  mySystem.enableSSH = false;
  mySystem.enableDocker = false;
  mySystem.enableTailscale = true;
  mySystem.enableSops = true;

  # Declarative Flatpak apps (nix-flatpak; daemon + wiring live in desktop.nix).
  mySystem.flatpakApps = [
    "io.missioncenter.MissionCenter"
    "com.github.wwmm.easyeffects"
  ];

  # If SSH is enabled on this host, put your real public keys here.
  mySystem.sshAuthorizedKeys = [ ];
}