# Intel hardware: CPU microcode, open GPU drivers with VA-API acceleration,
# and the kernel modules needed early in the initrd.
# Contributes a NixOS module to the `intel` slot.
{ ... }: {
  config.nixos.modules.intel = { config, lib, pkgs, ... }: {
    # Intel CPU microcode.
    hardware.cpu.intel.updateMicrocode = true;

    # Open GPU drivers with VA-API hardware acceleration.
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ]
      # Intel OpenCL (emulators like RPCS3, some games) — only when gaming.
      ++ lib.optional config.mySystem.appGroups.gaming.enable intel-compute-runtime;
    };

    # Intel kernel modules early for initrd.
    boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  };
}
