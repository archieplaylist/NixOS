# vm-host: NixOS guest intended to run inside a VM (VirtualBox or
# virt-manager). Picks the `base`, `desktop`, `uefi` and `vm-guest` slots.
{ config, ... }: {
  config.nixos.hosts.vm-host = { pkgs, ... }: {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.uefi
      config.nixos.modules.vm-guest
    ];

    # Pin the newest LTS kernel VirtualBox GuestAdditions 7.2.14 can build
    # against (the current default kernel breaks them). Bump when VirtualBox
    # catches up with a newer kernel.
    boot.kernelPackages = pkgs.linuxPackages_6_12;

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
  };
}
