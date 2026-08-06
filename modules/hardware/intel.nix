{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    # Intel CPU microcode.
    hardware.cpu.intel.updateMicrocode = true;

    # Open GPU drivers with VA-API hardware acceleration.
    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
    };

    # Intel kernel modules early for initrd.
    boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  };
}