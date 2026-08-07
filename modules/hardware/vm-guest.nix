{ config
, lib
, pkgs
, ...
}: {
  config = {
    # Kernel modules for KVM/QEMU (virt-manager): virtio disk/network/video.
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

    # QEMU guest agent (virsh shutdown, host/GUEST filesystem sync).
    services.qemuGuest.enable = true;

    # Spice clipboard/display integration (virt-manager).
    services.spice-vdagentd.enable = true;

    # VirtualBox guest additions (shared folders, dynamic resolution).
    virtualisation.virtualbox.guest.enable = true;
  };
}
