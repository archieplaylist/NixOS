# VM guest: virtio + qemu-agent + spice + vbox guest
# ponytail: qemu/spice/vbox agents coexist harmlessly — only the active hypervisor's agent does work.
_: {
  config.nixos.modules.vm-guest =
    let
      # VirtualBox GuestAdditions fix for kernel 6.12+ (drm_fb_helper_alloc_info removed).
      # Scoped here (only vm imports this) instead of a global overlay.
      # Re-check on VirtualBox >7.2.16 / kernel >6.18 — delete when vm builds without it.
      patchVboxGuestAdditions = kernelPackages:
        kernelPackages.extend (_final: prev: {
          virtualboxGuestAdditions = prev.virtualboxGuestAdditions.overrideAttrs (old: {
            prePatch = (old.prePatch or "") + ''
              fb=$(find src -name vbox_fb.c 2>/dev/null | head -n1)
              if [ -n "$fb" ]; then
                sed -i 's@info = drm_fb_helper_alloc_info(helper);@info = helper->info;@' "$fb"
                sed -i 's@if (IS_ERR(info))@if (IS_ERR(info) || !info)@' "$fb"
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
