{ config
, lib
, pkgs
, ...
}: {
  config = {
    networking.hostName = config.mySystem.hostname;

    system.stateVersion = "26.05";

    # Latest stable mainline kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Allow unfree packages (VSCode, Tailscale, Spotify, etc.).
    nixpkgs.config.allowUnfree = true;

    # Nix configuration: flakes, auto-optimise, garbage collection.
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # Firewall: DNS is fine, allow ping.
    networking.firewall = {
      enable = true;
      allowPing = true;
    };

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

    # Background TRIM for SSDs.
    services.fstrim.enable = true;

    # Compressed RAM swap (no swap partition needed).
    zramSwap.enable = true;
  };
}
