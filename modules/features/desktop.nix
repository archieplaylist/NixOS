# Desktop slot: shared X/Bluetooth/NetworkManager/Flatpak + PipeWire,
# GNOME/GDM, XFCE/LightDM, Plasma/SDDM. Sections merged, behavior unchanged.
_: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      (lib.mkIf config.mySystem.enableDesktop {
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          audio.enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };

        services = {
          blueman.enable = config.mySystem.desktop != "plasma";
          # ppd owns the CPU governor on desktop hosts; vm left to its host defaults
          power-profiles-daemon.enable = !config.mySystem.isVm;
          # ayu theme system-wide: /run/current-system/sw/share/themes is on
          # XDG_DATA_DIRS, so GTK, GNOME Shell, xfwm4 and the greeter find it
          ayu-theme.enable = true;
          flatpak = {
            enable = true;
            packages = config.mySystem.flatpakApps;
          };
        };

        # Icon theme for every DE. System-wide so it lands in
        # /run/current-system/sw/share/icons — nixpkgs patches flatpak to
        # expose that dir (and the nix store paths it symlinks to) inside
        # the sandbox, so flatpak apps get the same icons as native ones.
        environment.systemPackages = [ pkgs.mactahoe-icons ];

        hardware.bluetooth = {
          enable = true;
          powerOnBoot = false;
        };

        networking.networkmanager.enable = true;

        # nautilus trash + mtp/smb + sidebar mounts outside GNOME need these
        services.gvfs.enable = true;
        services.udisks2.enable = true;
      })

      # Flatpak sandboxes don't see the host theme by default:
      #  - xdg-config/gtk-3.0, xdg-config/gtk-4.0 → GTK settings (icon
      #    theme, font) + the Ayu libadwaita CSS
      #  - ~/.themes/Ayu-Dark → the theme itself (symlink into the nix
      #    store; see home/desktops/gnome.nix)
      (lib.mkIf (lib.elem config.mySystem.desktop [ "gnome" "xfce" ]) {
        services.flatpak.overrides.settings.global = {
          Context.filesystems = [
            "xdg-config/gtk-3.0"
            "xdg-config/gtk-4.0"
            "~/.themes/Ayu-Dark"
          ];
          Environment = {
            GTK_THEME = "Ayu-Dark";
            # libadwaita apps ignore GTK_THEME
            ADW_DEBUG_COLOR_SCHEME = "prefer-dark";
          };
        };
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "gnome") {
        services = {
          xserver.enable = true;
          displayManager.gdm.enable = true;
          gnome.gnome-keyring.enable = true;
          desktopManager.gnome = {
            enable = true;
            # system-wide override so the GDM login shell can load extensions
            # pre-login; the user session list is set in home/desktops/gnome.nix
            extraGSettingsOverrides = ''
              [org.gnome.shell]
              enabled-extensions=[${lib.concatMapStringsSep ", " (e: "'" + e.uuid + "'") config.mySystem.gnomeExtensions}]
            '';
            extraGSettingsOverridePackages = [
              pkgs.gsettings-desktop-schemas
              pkgs.gnome-shell
            ];
          };
        };
        security.pam.services.gdm.enableGnomeKeyring = true;
        security.pam.services.gdm-password.enableGnomeKeyring = lib.mkDefault true;

        environment.systemPackages = with pkgs; [
          gnome-tweaks
          dconf-editor
          networkmanagerapplet # nm-connection-editor: GNOME Settings has no add-ethernet UI
        ] ++ (map (e: pkgs.gnomeExtensions.${e.package}) config.mySystem.gnomeExtensions);

        environment.gnome.excludePackages = with pkgs; [
          gnome-software
          epiphany
          gnome-maps
          gnome-weather
          gnome-contacts
          # GNOME Games
          swell-foop
          tali
          five-or-more
          four-in-a-row
          lightsoff
          gnome-chess
          gnome-sudoku
          gnome-mines
        ];
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "xfce") {
        services = {
          xserver.enable = true;
          xserver.displayManager.lightdm = {
            enable = true;
            # same wallpaper as the session (modules/home/assets/wallpaper.jpg);
            # store path is world-readable so the lightdm user can load it
            background = ../home/assets/wallpaper.jpg;
            greeters.gtk = {
              enable = true;
              theme = {
                name = "Ayu-Dark";
                package = pkgs.ayu-theme;
              };
              iconTheme = {
                # dark variant to match xfconf Net/IconThemeName in home/desktops/xfce.nix
                name = "MacTahoe-dark";
                package = pkgs.mactahoe-icons;
              };
              cursorTheme = {
                name = "Bibata-Modern-Classic";
                package = pkgs.bibata-cursors;
                size = 20;
              };
              indicators = [ "~host" "~spacer" "~clock" "~spacer" "~session" "~a11y" "~power" ];
              extraConfig = ''
                font-name = Noto Sans 10
                xft-antialias = true
                xft-hintstyle = hintfull
              '';
            };
          };
          xserver.desktopManager.xfce.enable = true;
          gnome.gnome-keyring.enable = true;
          upower.enable = true;
        };

        # PAM unlocks the Login keyring at LightDM login; user daemon below
        # (home/desktops/xfce.nix) guarantees org.freedesktop.secrets + ssh
        # socket for vivaldi/vscode/discord even if PAM races the session
        security.pam.services.lightdm.enableGnomeKeyring = true;

        # Stock xfce4-panel again (eww bar removed 2026-10). xfce4-session
        # spawns the panel as a session client; the layout stays user-owned
        # xfconf state — don't fight it here.
        environment.systemPackages = with pkgs; [
          seahorse # GUI to verify/unlock the Login keyring after first boot
          mousepad
          ristretto
          xfce4-clipman-plugin
          xfce4-whiskermenu-plugin
          catfish
        ];

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
          config.common.default = "gtk";
        };
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "plasma") {
        services = {
          displayManager.sddm = {
            enable = true;
            wayland.enable = true;
          };
          desktopManager.plasma6.enable = true;
          gnome.gnome-keyring.enable = true;
        };

        # shared Login keyring unlocks at SDDM login, same as the other DEs
        security.pam.services.sddm.enableGnomeKeyring = true;

        environment.systemPackages = with pkgs.kdePackages; [
          plasma-browser-integration
        ];

        environment.plasma6.excludePackages = with pkgs.kdePackages; [
          discover
        ];
      })

    ];
  };
}
