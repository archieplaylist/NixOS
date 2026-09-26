# vm — cinnamon guest (qemu/virtualbox), no gaming/dev
{ config, ... }: {
  config.nixos.hosts.vm = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.uefi
      config.nixos.modules.vm-guest
    ];

    mySystem.hostname = "nixvms";
    mySystem.isVm = true;
    mySystem.desktop = "cinnamon";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = true;
    mySystem.enableDocker = false;
    mySystem.enableTailscale = true;

    mySystem.appGroups.browsers.enable = true;
    mySystem.appGroups.media.enable = true;

    mySystem.enableLuks = true;

    # vm never prints — save CUPS + Avahi broadcast
    services.printing.enable = false;
    services.system-config-printer.enable = false;

    # 8GB vm disk can't hold 10 generations
    boot.loader.systemd-boot.configurationLimit = 5;

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
