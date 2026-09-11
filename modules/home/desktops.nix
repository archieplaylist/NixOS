# mario home desktops: GNOME dconf (gnome), plasma-manager (plasma),
# XFCE packages (xfce), GTK/icon/cursor theming (themes, GNOME only).
# Sections merged, behavior unchanged.
_: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: lib.mkMerge [
    {
      dconf = {
        enable = osConfig.mySystem.desktop == "gnome";
        settings = lib.mkIf (osConfig.mySystem.desktop == "gnome") {
          "org/gnome/shell" = {
            enabled-extensions = map (e: e.uuid) osConfig.mySystem.gnomeExtensions;
          };
          "org/gnome/shell/extensions/user-theme" = {
            name = "Orchis-Dark";
          };
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
            resize-with-right-button = true;
          };
          "org/gnome/desktop/interface" = {
            gtk-enable-primary-paste = true;
            monospace-font-name = "JetBrainsMono Nerd Font 11";
            document-font-name = "Noto Sans 11";
          };
          "org/gnome/desktop/sound" = {
            allow-volume-above-100-percent = true;
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${./assets/wallpaper.png}";
            picture-uri-dark = "file://${./assets/wallpaper.png}";
            picture-options = "zoom";
          };
        };
      };
    }

    {
      programs.plasma = lib.mkIf (osConfig.mySystem.desktop == "plasma") {
        enable = true;
        overrideConfig = false; # ponytail: true rewrites kwinrc/plasmarc every login → 3-5s plasmashell restart
      };
    }

    (lib.mkIf (osConfig.mySystem.desktop == "xfce") {
      home.packages = with pkgs; [
        xfce4-terminal
        xfce4-screenshooter
        xfce4-clipman-plugin
        xfce4-whiskermenu-plugin
        xfce4-power-manager
        xfce4-appfinder
        mousepad
        seahorse
        # ponytail: packages only, no declarative config — set manually in Appearance
        orchis-theme
        tela-circle-icon-theme
        bibata-cursors
      ];
    })

    # GTK/icon/cursor/font theming — GNOME only (plasma/xfce stay stock defaults)
    # Orchis-Dark / Tela-circle-dark / Bibata (Orchis https://github.com/vinceliuice/Orchis-theme)
    (lib.mkIf (osConfig.mySystem.desktop == "gnome") {
      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        font = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
          size = 10;
        };
        theme = {
          name = "Orchis-Dark";
          package = pkgs.orchis-theme;
        };
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
        cursorTheme = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 20;
        };
        gtk2.force = true;
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    })
  ];
}
