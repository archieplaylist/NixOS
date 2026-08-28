# Intel CPU + GPU (VA-API) + initrd modules
{ ... }: {
  config.nixos.modules.intel = { config, lib, pkgs, ... }: {
    hardware.cpu.intel.updateMicrocode = true;

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ]
      ++ lib.optional config.mySystem.appGroups.gaming.enable intel-compute-runtime;
    };

    boot.initrd.availableKernelModules = [ "vmd" "ahci" "xhci_pci" "nvme" "usb_storage" "sd_mod" "usbhid" ];
  };
}
