# primary home gnome: dconf settings, GTK/icon/cursor/font theming (Orchis-Dark),
# alacritty basics (noctalia owns alacritty.toml on niri, so niri excluded).
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkMerge [
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
            picture-uri = "file://${../assets/wallpaper.jpg}";
            picture-uri-dark = "file://${../assets/wallpaper.jpg}";
            picture-options = "zoom";
          };
        };
      };
    }

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

      xdg.configFile."alacritty/alacritty.toml".text = ''
        [window]
        padding = { x = 12, y = 12 }
        opacity = 0.80

        [font]
        size = 11

        [font.normal]
        family = "JetBrainsMono Nerd Font"
      '';
    })
  ];
}
