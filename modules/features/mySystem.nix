# Per-host flags + GNOME extensions source of truth (base slot)
{ ... }: {
  config.nixos.modules.base = { config, lib, ... }: {
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
      appGroups = lib.mkOption {
        type = lib.types.submodule {
          options = {
            browsers = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Web browsers (firefox, chromium, vivaldi).";
              };
            };
            media = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Media players and tooling (vlc, mpv, yt-dlp, ffmpeg).";
              };
            };
            office = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Office and productivity (joplin, onlyoffice, libreoffice).";
              };
            };
            comms = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Communication apps (discord).";
              };
            };
            editor = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Code editors (vscode).";
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
      enableLuks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable LUKS2 encryption for the root partition (fresh install only; requires repartition).";
      };
      enableTpm2 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable TPM2 auto-unlock for LUKS (requires enableLuks and TPM2 hardware; passphrase remains as fallback).";
      };
      enableSecureBoot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Secure Boot via lanzaboote (requires enableLuks, implies TPM2 PCR 7 protection).";
      };
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

    config = {
      mySystem.flatpakApps = [
        "org.localsend.localsend_app"
        "it.mijorus.gearlever"
        "com.github.tchx84.Flatseal"
      ];

      mySystem.gnomeExtensions = lib.mkIf (config.mySystem.desktop == "gnome") [
        { uuid = "appindicatorsupport@rgcjonas.gmail.com"; package = "appindicator"; }
        { uuid = "blur-my-shell@aunetx"; package = "blur-my-shell"; }
        { uuid = "caffeine@patapon.info"; package = "caffeine"; }
        { uuid = "clipboard-indicator@tudmotu.com"; package = "clipboard-indicator"; }
        { uuid = "CoverflowAltTab@palatis.blogspot.com"; package = "coverflow-alt-tab"; }
        { uuid = "dash-to-dock@micxgx.gmail.com"; package = "dash-to-dock"; }
        { uuid = "drive-menu@gnome-shell-extensions.gcampax.github.com"; package = "removable-drive-menu"; }
        { uuid = "impatience@gfxmonk.net"; package = "impatience"; }
        { uuid = "just-perfection-desktop@just-perfection"; package = "just-perfection"; }
        { uuid = "tailscale-gnome-qs@tailscale-qs.github.io"; package = "tailscale-qs"; }
        { uuid = "user-theme@gnome-shell-extensions.gcampax.github.com"; package = "user-themes"; }
      ];

      assertions = [
        {
          assertion = !config.mySystem.enableTpm2 || config.mySystem.enableLuks;
          message = "mySystem.enableTpm2 requires mySystem.enableLuks = true";
        }
        {
          assertion = !config.mySystem.enableSecureBoot || config.mySystem.enableLuks;
          message = "mySystem.enableSecureBoot requires mySystem.enableLuks = true";
        }
      ];

      warnings = lib.optional (config.mySystem.enableTpm2 && !config.mySystem.enableSecureBoot)
        "TPM2 auto-unlock without Secure Boot is vulnerable to Evil Maid — consider enabling mySystem.enableSecureBoot";
    };
  };
}
