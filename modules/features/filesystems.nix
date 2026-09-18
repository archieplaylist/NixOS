# Two-partition layout — plain XFS (existing installs) or LUKS2-wrapped XFS (fresh installs only)
# Ponytail: non-LUKS hosts keep the stable manual fileSystems; LUKS hosts are fully disko-declared
# (disko generates boot.initrd.luks + fileSystems from disko.devices). setup.sh still does the
# actual sgdisk/cryptsetup so no hard-coded /dev/sdX device is needed in the config.
_: {
  config.nixos.modules.base = { config, lib, ... }: {
    config = lib.mkMerge [
      # Plain layout: / (nixos-root) + /boot (nixos-boot, vfat)
      (lib.mkIf (!config.mySystem.enableLuks) {
        boot.initrd.supportedFilesystems = [ "xfs" ];

        fileSystems = {
          "/" = {
            device = "/dev/disk/by-label/nixos-root";
            fsType = "xfs";
            options = [ "noatime" ];
          };
          "/boot" = {
            device = "/dev/disk/by-label/nixos-boot";
            fsType = "vfat";
            options = [ "fmask=0077" "dmask=0077" ];
          };
        };
      })

      # LUKS2 layout: LUKS partition (GPT label nixos-root; LUKS container label nixos-root-luks,
      # set by setup.sh cryptsetup --label, is informational only) → mapper cryptroot → XFS (label nixos-root)
      (lib.mkIf config.mySystem.enableLuks {
        # systemd initrd required for TPM2 auto-unlock (systemd-cryptenroll); harmless for passphrase-only
        boot.initrd.systemd.enable = true;

        disko.devices.disk.nixos = {
          type = "disk";
          device = lib.mkDefault "/dev/sda"; # override per host if using `disko --mode disko`; setup.sh ignores this
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                label = "nixos-boot"; # must match setup.sh sgdisk -c 1:nixos-boot
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "fmask=0077" "dmask=0077" ];
                };
              };
              luks = {
                size = "100%";
                label = "nixos-root"; # must match setup.sh sgdisk -c 2:nixos-root
                content = {
                  type = "luks";
                  name = "cryptroot";
                  settings = {
                    allowDiscards = true;
                    bypassWorkqueues = true;
                    # only probe the TPM when a key is enrolled; otherwise every
                    # boot would ask the TPM for a key that does not exist
                    crypttabExtraOpts = lib.mkIf config.mySystem.enableTpm2 [ "tpm2-device=auto" ];
                  };
                  content = {
                    type = "filesystem";
                    format = "xfs";
                    mountpoint = "/";
                    mountOptions = [ "noatime" ];
                  };
                };
              };
            };
          };
        };
      })
    ];
  };
}
