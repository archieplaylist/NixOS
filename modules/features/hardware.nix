# Hardware slots: intel, laptop, uefi, vm-guest. One file, slot names unchanged
# so host imports stay as-is.
_: {
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

  config.nixos.modules.laptop = { config, lib, ... }: {
    config = lib.mkIf config.mySystem.enableLaptop {
      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };

  config.nixos.modules.uefi = { config, lib, ... }: {
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
    boot.loader.timeout = 1;

    # systemd-boot unless Secure Boot is enabled (lanzaboote replaces it)
    boot.loader.systemd-boot.enable = !config.mySystem.enableSecureBoot;
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

    boot.lanzaboote.enable = config.mySystem.enableSecureBoot;
    boot.lanzaboote.pkiBundle = "/var/lib/sbctl";
    boot.lanzaboote.configurationLimit = lib.mkIf config.mySystem.enableSecureBoot 10;
  };

  # VM guest: virtio + qemu-agent + spice + vbox guest
  # qemu/spice/vbox agents coexist harmlessly — only the active hypervisor's agent does work.
  config.nixos.modules.vm-guest =
    let
      # VirtualBox GuestAdditions fixes for newer kernels (drm fb_helper API churn).
      #  - kernel 6.12+: drm_fb_helper_alloc_info removed (vbox_fb.c).
      #  - kernel 6.18+: drm_fb_helper_restore_fbdev_mode_unlocked gained bool force (vbox_main.c).
      # Scoped here (only vm imports this) instead of a global overlay.
      # Re-check on VirtualBox with upstream 6.18 support — delete when vm builds without it.
      patchVboxGuestAdditions = kernelPackages:
        kernelPackages.extend (_final: prev: {
          virtualboxGuestAdditions = prev.virtualboxGuestAdditions.overrideAttrs (old: {
            prePatch = (old.prePatch or "") + ''
              fb=$(find src -name vbox_fb.c 2>/dev/null | head -n1)
              if [ -n "$fb" ]; then
                sed -i 's@info = drm_fb_helper_alloc_info(helper);@info = helper->info;@' "$fb"
                sed -i 's@if (IS_ERR(info))@if (IS_ERR(info) || !info)@' "$fb"
              fi
              main=$(find src -name vbox_main.c 2>/dev/null | head -n1)
              if [ -n "$main" ]; then
                sed -i 's@drm_fb_helper_restore_fbdev_mode_unlocked(&vbox->fbdev->helper)@drm_fb_helper_restore_fbdev_mode_unlocked(\&vbox->fbdev->helper, true)@' "$main"
              fi
            '';
          });
        });
    in
    {
      nixpkgs.overlays = [
        (_final: prev: {
          linuxPackages = patchVboxGuestAdditions prev.linuxPackages;
          linuxPackages_latest = patchVboxGuestAdditions prev.linuxPackages_latest;
        })
      ];

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
