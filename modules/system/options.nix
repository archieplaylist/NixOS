{ lib, ... }: {
  options.mySystem = {
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Network hostname for the host.";
    };
    sshAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys for the primary user.";
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
    enableSSH = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the OpenSSH server.";
    };
    enableDocker = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the Docker daemon.";
    };
    enableVirtualBox = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the VirtualBox host (with kernel modules).";
    };
    flatpakApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Flatpak app IDs to install declaratively via nix-flatpak.";
    };
    enableTailscale = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the Tailscale daemon.";
    };
    enableSops = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable sops-nix secret decryption.";
    };
    # Single source of truth for GNOME Shell extensions: enabled in the user's
    # dconf db (home/mario.nix) and the matching package installed (desktop.nix).
    # Each entry maps an extension-gnome.org UUID to a pkgs.gnomeExtensions attr.
    gnomeExtensions = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          uuid = lib.mkOption {
            type = lib.types.str;
            description = "Extension UUID as registered on extensions.gnome.org.";
          };
          package = lib.mkOption {
            type = lib.types.str;
            description = "Attribute name under pkgs.gnomeExtensions.";
          };
        };
      });
      default = [
        { uuid = "appindicatorsupport@rgcjonas.gmail.com"; package = "appindicator"; }
        { uuid = "blur-my-shell@aunetx"; package = "blur-my-shell"; }
        { uuid = "caffeine@patapon.info"; package = "caffeine"; }
        { uuid = "clipboard-indicator@tudmotu.com"; package = "clipboard-indicator"; }
        { uuid = "CoverflowAltTab@palatis.blogspot.com"; package = "coverflow-alt-tab"; }
        { uuid = "dash-to-dock@micxgx.gmail.com"; package = "dash-to-dock"; }
        { uuid = "drive-menu@gnome-shell-extensions.gcampax.github.com"; package = "removable-drive-menu"; }
        { uuid = "just-perfection-desktop@just-perfection"; package = "just-perfection"; }
        { uuid = "tailscale-gnome-qs@tailscale-qs.github.io"; package = "tailscale-qs"; }
        { uuid = "user-theme@gnome-shell-extensions.gcampax.github.com"; package = "user-themes"; }
      ];
      description = "GNOME Shell extensions to enable and install.";
    };
  };
}