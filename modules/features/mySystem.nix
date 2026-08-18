# mySystem: per-host flags and the single source of truth for GNOME extensions.
#
# Contributes a NixOS module to the `base` slot: the system side
# (desktop.nix) and the user side (home/* via `osConfig.mySystem`) both read
# these, never home-manager options directly.
{ ... }: {
  config.nixos.modules.base = { lib, ... }: {
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
        description = "Enable the desktop environment.";
      };
      desktop = lib.mkOption {
        type = lib.types.enum [ "gnome" "plasma" "xfce" ];
        default = "gnome";
        description = "Desktop environment for this host: gnome, plasma or xfce.";
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
      # Per-host application group toggles. Single source of truth: the system
      # side (desktop.nix, e.g. Steam/32-bit OpenGL) and the user side
      # (home/*.nix packages via `osConfig.mySystem.appGroups`) both read these.
      appGroups = lib.mkOption {
        type = lib.types.submodule {
          options = {
            general = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "General-purpose applications (browsers, media, editors).";
              };
            };
            gaming = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Gaming applications (Steam, MangoHud, gamescope, Heroic).";
              };
            };
            dev = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Development tooling (editors, languages, CLIs).";
              };
            };
            work = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Work applications (dbeaver-bin, filezilla, remmina).";
              };
            };
          };
        };
        default = { };
        description = "Per-host application group toggles (mirrored to home-manager).";
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
      enableSmartd = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the smartd disk health monitoring service.";
      };
      # Single source of truth for GNOME Shell extensions: enabled in the user's
      # dconf db (modules/home/gnome.nix) and the matching package installed
      # (desktop.nix). Each entry maps an extension-gnome.org UUID to a
      # pkgs.gnomeExtensions attr.
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
        default = [ ];
        description = "GNOME Shell extensions to enable and install.";
      };
    };

    # Base extension list as a regular definition: modules extending it (e.g.
    # the gamemode extension gated on mySystem.appGroups.gaming in desktop.nix)
    # use mkAfter at the same priority, so both lists merge.
    config.mySystem.gnomeExtensions = [
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
  };
}
