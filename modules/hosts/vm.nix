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

    # Flatpak: inherits base list from mySystem.nix (localsend/gearlever/flatseal).

    # The VM doesn't need heavy gaming or development packages.
    mySystem.appGroups.gaming.enable = false;
    mySystem.appGroups.dev.enable = false;

    # QEMU VM variant for `nixos-rebuild build-vm --flake .#vm` — test the
    # config without VirtualBox. Uses virtio and a small disk.
    virtualisation.vmVariant = {
      virtualisation = {
        memorySize = 4096;
        cores = 4;
        diskSize = 8192;
        graphics = true;
        qemu.options = [ "-device virtio-vga" ];
      };
    };
  };
}
