# System fundamentals for every host: locale, kernel, nix, firewall, avahi,
# printing, nix-ld, AppImages, firmware and fonts. Store/disk maintenance
# (GC, TRIM, zram, smartd, journald, tmpfiles) lives in optimisation.nix.
# Contributes a NixOS module to the `base` slot.
{ ... }: {
  config.nixos.modules.base = { config, lib, pkgs, ... }: {
    config = {
      networking.hostName = config.mySystem.hostname;

      system.stateVersion = "26.05";

      # Locale: en_US.UTF-8 with only that locale generated.
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

      # Timezone.
      time.timeZone = "Asia/Jakarta";

      # Latest stable mainline kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      # Allow unfree packages (VSCode, Tailscale, Spotify, etc.).
      nixpkgs.config.allowUnfree = true;

      # Firewall: DNS is fine, allow ping. LocalSend (flatpak, all hosts)
      # listens on TCP+UDP 53317 for discovery and file transfer.
      networking.firewall = {
        enable = true;
        allowPing = true;
        allowedTCPPorts = [ 53317 ];
        allowedUDPPorts = [ 53317 ];
      };

      # ZeroConf/mDNS: .local hostname resolution and service discovery
      # (printer detection, LocalSend, etc.). Explicit because printing and
      # system-config-printer rely on it.
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        nssmdns6 = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
        };
      };

      # CUPS printing + GNOME's printer settings app (system-config-printer).
      services.printing = {
        enable = true;
        drivers = [ pkgs.gutenprint ];
      };
      services.system-config-printer.enable = true;

      # Run third-party dynamically-linked binaries (VS Code extensions like
      # Kilo Code/Cline, JetBrains remote, etc.) via nix-ld. The module's
      # default library set (zlib, openssl, curl, systemd, …) is merged with
      # the extra libs below, which cover Node-based CLIs and desktop deps.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          gcc-unwrapped.lib # libgcc_s.so.1
          glib
          libsecret # VS Code keyring
          icu # node-based CLIs (kilo, etc.)
          krb5
          libnotify
          nspr
          nss
        ];
      };

      # Running AppImages: binfmt_misc hands them to appimage-run, which
      # extracts and executes them without needing FUSE.
      boot.binfmt.registrations.appimage = {
        wrapInterpreterInShell = false;
        interpreter = "${pkgs.appimage-run}";
        recognitionType = "magic";
        offset = 0;
        magicOrExtension = ''\x7fELF....AI\x02'';
      };

      # Firmware.
      hardware.enableRedistributableFirmware = lib.mkDefault true;

      # Common fonts.
      fonts.packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
      ];
    };
  };
}
