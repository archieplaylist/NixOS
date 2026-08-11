{ ...
}: {
  imports = [
    ./common.nix
    ../modules/system/desktop.nix
    ../modules/hardware/vm-guest.nix
  ];

  # --- Host identity -----------------------------------------------------
  # NixOS guest intended to run inside a VM (VirtualBox or virt-manager).
  mySystem.hostname = "nixvms";
  mySystem.enableDesktop = true;
  mySystem.enableSSH = true;
  mySystem.enableDocker = false;
  mySystem.enableTailscale = false;
  mySystem.enableSops = false;

  # Declarative Flatpak apps (nix-flatpak; daemon + wiring live in desktop.nix).
  mySystem.flatpakApps = [
    "com.github.wwmm.easyeffects"
    "org.localsend.localsend_app"
    "it.mijorus.gearlever"
    "com.github.tchx84.Flatseal"
    "com.mattjakeman.ExtensionManager"
  ];

  # The VM doesn't need heavy gaming or development packages.
  mySystem.appGroups.gaming.enable = false;
  mySystem.appGroups.dev.enable = false;
}