# Intel hardware: CPU microcode, open GPU drivers with VA-API acceleration,
# and the kernel modules needed early in the initrd.
# Contributes a NixOS module to the `intel` slot.
{ ... }: {
  config.nixos.modules.intel = { pkgs, ... }: {
    # Intel CPU microcode.
    hardware.cpu.intel.updateMicrocode = true;

    # Open GPU drivers with VA-API hardware acceleration.
    hardware.graphics = {
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
