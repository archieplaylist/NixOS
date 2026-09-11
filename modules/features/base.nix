# Base slot: fundamentals for every host — locale/firewall/printing (basics),
# SSH/Docker/Tailscale/VirtualBox (services), store maintenance (optimisation),
# nix-ld, user mario. Sections merged, behavior unchanged.
_: {
  config.nixos.modules.base = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      {
        networking.hostName = config.mySystem.hostname;
        system.stateVersion = "26.05";

        i18n.defaultLocale = "en_US.UTF-8";
        i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
        time.timeZone = "Asia/Jakarta";

        boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;
        nixpkgs.config.allowUnfree = true;

        # LocalSend (flatpak) needs TCP+UDP 53317 — desktop hosts only
        networking.firewall.enable = true;
        networking.firewall.allowPing = true;
        networking.firewall.allowedTCPPorts = lib.mkIf config.mySystem.enableDesktop [ 53317 ];
        networking.firewall.allowedUDPPorts = lib.mkIf config.mySystem.enableDesktop [ 53317 ];

        services.avahi = {
          enable = true;
          nssmdns4 = true;
          nssmdns6 = true;
          publish = {
            enable = config.mySystem.enableDesktop;
            addresses = true;
            workstation = true;
          };
        };

        # ponytail: no explicit drivers — add gutenprint when a printer needs it
        services.printing.enable = lib.mkDefault true;
        services.system-config-printer.enable = lib.mkDefault true;

        boot.binfmt.registrations.appimage = {
          wrapInterpreterInShell = false;
          interpreter = "${pkgs.appimage-run}";
          recognitionType = "magic";
          offset = 0;
          magicOrExtension = ''\x7fELF....AI\x02'';
        };

        hardware.enableRedistributableFirmware = lib.mkDefault true;

        fonts.packages = with pkgs; [
          nerd-fonts.fira-code
          nerd-fonts.jetbrains-mono
          noto-fonts
          noto-fonts-color-emoji
          liberation_ttf
        ];
      }

      {
        # ponytail: password login on purpose (keys optional) — user password comes from /etc/hashed-password
        services.openssh = lib.mkIf config.mySystem.enableSSH {
          enable = true;
          settings = {
            PasswordAuthentication = true;
            PermitRootLogin = "no";
            KbdInteractiveAuthentication = false;
          };
        };

        services.tailscale = lib.mkIf config.mySystem.enableTailscale {
          enable = true;
        };

        services.smartd = lib.mkIf config.mySystem.enableSmartd {
          enable = true;
          autodetect = true;
        };

        virtualisation.docker = lib.mkIf config.mySystem.enableDocker {
          enable = true;
          enableOnBoot = true;
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
        };

        virtualisation.virtualbox = lib.mkIf config.mySystem.enableVirtualBox {
          host.enable = true;
        };

        environment.systemPackages = with pkgs; [
          curl
          wget
          ripgrep
          unzip
        ];
      }

      {
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

        services.earlyoom.enable = true; # ponytail: kill hungriest process before full freeze

        services.ananicy = lib.mkIf (!config.mySystem.isVm) {
          enable = true;
          package = pkgs.ananicy-cpp;
          rulesProvider = pkgs.ananicy-rules-cachyos; # ponytail: cachyos rules = best perf without custom tuning
        };

        services.journald.extraConfig = ''
          SystemMaxUse=500M
          SystemKeepFree=1G
          MaxRetentionSec=14day
        '';

        zramSwap = {
          enable = true;
          algorithm = "zstd";
          # ponytail: vm guest is tiny — 25% zram, no scheduler tuning
          memoryPercent = if config.mySystem.isVm then 25 else 100;
        };

        # zram-only swap tuning + keep dentry cache for thunar responsiveness
        boot.kernel.sysctl = {
          "vm.page-cluster" = 0;
          "vm.swappiness" = 180;
          "vm.watermark_boost_factor" = 0;
          "vm.watermark_scale_factor" = 125;
          "vm.vfs_cache_pressure" = 50; # ponytail: 50 keeps inode cache, faster 2nd open
        };

        systemd.tmpfiles.rules = [
          "d /home/*/.cache/mozilla/firefox/*/cache2 - - - 7d"
          "d /home/*/.cache/chromium/*/Cache - - - 7d"
          "d /home/*/.cache/thumbnails - - - 30d"
          "d /tmp/nix-build-* - - - 3d"
          "d /var/tmp/nix-build-* - - - 3d"
        ];
      }

      # nix-ld: dynamic linker for unpatched binaries (AppImages, vendor tarballs).
      # To temporarily disable: unset NIX_LD. To find a missing lib:
      # nix run github:nix-community/nix-index-database -- lib/<name>.so
      # ponytail: minimal core only — add libs when ldd/nix-index says so, not just in case.
      {
        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            zstd
            curl
            openssl
            glib
            gtk3
            fontconfig
            freetype
            alsa-lib
            libGL
            libX11
            nss
            nspr
            cups
            expat
          ];
        };
      }

      # User mario — hash from /etc/hashed-password (written by setup.sh, not stored in flake)
      {
        users.users.mario = {
          isNormalUser = true;
          description = "Mario";
          extraGroups =
            [ "wheel" "video" "audio" ]
            ++ lib.optionals config.mySystem.enableDesktop [ "networkmanager" ]
            ++ lib.optionals config.mySystem.enableDocker [ "docker" ]
            ++ lib.optionals config.mySystem.enableVirtualBox [ "vboxusers" ]
            ++ lib.optionals config.mySystem.appGroups.gaming.enable [ "gamemode" "input" ];
          openssh.authorizedKeys.keys = config.mySystem.sshAuthorizedKeys;
          hashedPasswordFile = "/etc/hashed-password";
        };
      }
    ];
  };
}
