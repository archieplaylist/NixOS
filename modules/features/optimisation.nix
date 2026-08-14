# Store and disk maintenance: nix garbage collection + auto-optimise, TRIM,
# zram, smartd health monitoring, journald bounds and tmpfiles cleanup.
# Contributes a NixOS module to the `base` slot.
{ ... }: {
  config.nixos.modules.base = { lib, ... }: {
    config = {
      # Nix configuration: flakes, auto-optimise, garbage collection, and
      # automatic cleanup when the store is low on free space.
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        min-free = 5368709120; # 5 GiB floor; trigger GC below this
        max-free = 10737418240; # free up to 10 GiB per cycle
      };
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      # Background TRIM for SSDs.
      services.fstrim.enable = true;

      # Compressed RAM swap (no swap partition needed).
      zramSwap.enable = true;

      # Disk health monitoring (SMART). The desktop is an NVMe, and smartd
      # detects all disks automatically.
      services.smartd = {
        enable = true;
        autodetect = true;
      };

      # Keep the journal bounded so it can't fill the disk.
      services.journald.extraConfig = ''
        SystemMaxUse=500M
        SystemKeepFree=1G
        MaxRetentionSec=30day
      '';

      # Clear browser caches and other disposable data on a schedule
      # (systemd-tmpfiles --clean, daily). Firefox and Chromium both live here.
      systemd.tmpfiles.rules = [
        "d /home/*/.cache/mozilla/firefox/*/cache2 - - - 7d"
        "d /home/*/.cache/chromium/*/Cache - - - 7d"
        "d /home/*/.cache/thumbnails - - - 30d"
        "d /tmp/nix-build-* - - - 3d"
        "d /var/tmp/nix-build-* - - - 3d"
      ];
    };
  };
}
