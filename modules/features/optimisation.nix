# Store/disk maintenance: GC, TRIM, zram, journald, tmpfiles (base slot)
{ ... }: {
  config.nixos.modules.base = { pkgs, ... }: {
    config = {
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        min-free = 5368709120;
        max-free = 10737418240;
      };

      # nh helper — weekly `nh clean all` replaces nix.gc.automatic
      programs.nh = {
        enable = true;
        flake = "/home/mario/nixos";
        clean = {
          enable = true;
          dates = "weekly";
          extraArgs = "--keep 5 --keep-since 7d --no-direnv";
        };
      };

      services.fstrim = {
        enable = true;
        interval = "weekly";
      };

      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 100;
      };

      # zram-only swap tuning + keep dentry cache for thunar responsiveness
      boot.kernel.sysctl = {
        "vm.page-cluster" = 0;
        "vm.swappiness" = 180;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
        "vm.vfs_cache_pressure" = 50; # ponytail: 50 keeps inode cache, faster 2nd open
      };

      services.earlyoom.enable = true; # ponytail: kill hungriest process before full freeze

      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos; # ponytail: cachyos rules = best perf without custom tuning
      };

      services.journald.extraConfig = ''
        SystemMaxUse=500M
        SystemKeepFree=1G
        MaxRetentionSec=14day
      '';

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
