# vm — xfce guest (qemu/virtualbox), no gaming/dev
{ config, ... }: {
  config.nixos.hosts.vm = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.uefi
      config.nixos.modules.vm-guest
    ];

    mySystem.hostname = "nixvms";
    mySystem.desktop = "xfce";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = true;
    mySystem.enableDocker = false;
    mySystem.enableTailscale = false;

    mySystem.appGroups.gaming.enable = false;
    mySystem.appGroups.dev.enable = false;
    mySystem.appGroups.work.enable = false;
    mySystem.appGroups.comms.enable = false;
    mySystem.appGroups.office.enable = false;
    mySystem.appGroups.editor.enable = false;
    mySystem.appGroups.ai.enable = false;

    # ponytail: vm never prints — save CUPS + Avahi broadcast
    services.printing.enable = false;
    services.system-config-printer.enable = false;

    # ponytail: 8GB vm disk can't hold 10 generations
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
