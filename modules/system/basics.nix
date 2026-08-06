{
  config,
  lib,
  pkgs,
  ...
}: {
  options.mySystem = {
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Network hostname for the host.";
    };
    enableDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the GNOME desktop environment.";
    };
    enableLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable laptop power management.";
    };
  };

  config = {
    networking.hostName = config.mySystem.hostname;

    system.stateVersion = "24.11";

    # Nix configuration: flakes, auto-optimise, garbage collection.
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # Firewall: DNS is fine, allow ping.
    networking.firewall = {
      enable = true;
      allowPing = true;
    };

    # Firmware.
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # Common fonts.
    fonts.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
    ];

    # Background TRIM for SSDs.
    services.fstrim.enable = true;
  };
}