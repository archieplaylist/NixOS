# vm: NixOS guest intended to run inside a VM (VirtualBox or
# virt-manager). Picks the `base`, `desktop`, `uefi` and `vm-guest` slots.
{ config, ... }: {
  config.nixos.hosts.vm = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.uefi
      config.nixos.modules.vm-guest
    ];

    # SMART monitoring is pointless on a VM's virtual disk.
    mySystem.enableSmartd = false;

    mySystem.hostname = "nixvms";
    mySystem.desktop = "xfce";
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
    ];

    # The VM doesn't need heavy gaming or development packages.
    mySystem.appGroups.gaming.enable = false;
    mySystem.appGroups.dev.enable = false;
  };
}
