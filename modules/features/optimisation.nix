# Store and disk maintenance: nix auto-optimise + low-space GC, weekly `nh
# clean` garbage collection, TRIM, zram, smartd health monitoring, journald
# bounds and tmpfiles cleanup.
# Contributes a NixOS module to the `base` slot.
{ ... }: {
  config.nixos.modules.base = { ... }: {
    config = {
      # Nix configuration: flakes, auto-optimise, and automatic cleanup when
      # the store is low on free space. Weekly garbage collection is handled
      # by `nh clean` (programs.nh.clean below), which replaces nix.gc.
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        min-free = 5368709120; # 5 GiB floor; trigger GC below this
        max-free = 10737418240; # free up to 10 GiB per cycle
        # Official binary cache for prebuilt packages.
        substituters = [ "https://cache.nixos.org" ];
        trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      };

      # nh — the Nix CLI helper (https://github.com/nix-community/nh), installed
      # system-wide. `NH_FLAKE` points at this repo so `nh os switch -H <host>`
      # works without a path. The weekly `nh-clean` timer runs `nh clean all`
      # (keeps 3 generations + anything newer than 7 days, preserves nix-direnv
      # gcroots via --no-direnv) and replaces the old nix.gc.automatic.
      programs.nh = {
        enable = true;
        flake = "/home/mario/nixos";
        clean = {
          enable = true;
          dates = "weekly";
          extraArgs = "--keep 5 --keep-since 7d --no-direnv";
        };
      };

      # Background TRIM for SSDs (weekly).
      services.fstrim = {
        enable = true;
        interval = "weekly";
      };

      # Compressed RAM swap (no swap partition needed).
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 100;
      };

      # Keep the journal bounded so it can't fill the disk.
      services.journald.extraConfig = ''
        SystemMaxUse=500M
        SystemKeepFree=1G
        MaxRetentionSec=14day
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
