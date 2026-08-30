# vm — xfce guest (qemu/virtualbox), no gaming/dev
{ config, ... }: {
  config.nixos.hosts.vm = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.uefi
      config.nixos.modules.vm-guest
    ];

    mySystem.enableSmartd = false;
    mySystem.hostname = "nixvms";
    mySystem.desktop = "xfce";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = true;
    mySystem.enableDocker = false;
    mySystem.enableTailscale = false;
    mySystem.enableSops = false;
    
    mySystem.enableLuks = false; # vm never encrypted — no TPM, disposable
    mySystem.enableTpm2 = false;
    mySystem.enableSecureBoot = false;

    mySystem.appGroups.gaming.enable = false;
    mySystem.appGroups.dev.enable = false;

    # ponytail: vm never prints — save CUPS + Avahi broadcast
    services.printing.enable = false;
    services.system-config-printer.enable = false;

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
