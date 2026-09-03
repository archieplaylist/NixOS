# VM guest: virtio + qemu-agent + spice + vbox guest
_: {
  config.nixos.modules.vm-guest = {
    boot.initrd.availableKernelModules = [
      "ahci"
      "virtio_pci"
      "virtio_blk"
      "virtio_net"
      "virtio_scsi"
      "virtio_console"
      "usb_storage"
      "sd_mod"
    ];

    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true;
    virtualisation.virtualbox.guest.enable = true;
  };
}
