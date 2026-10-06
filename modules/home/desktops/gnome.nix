# primary home gnome: dconf settings, GTK/icon/cursor/font theming (MacTahoe-Dark).
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
            name = "MacTahoe-Dark";
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

    # MacTahoe-Dark GTK theme shared by GNOME + XFCE (both GTK-based);
    # the color-scheme dconf key below stays GNOME-only
    (lib.mkIf (builtins.elem osConfig.mySystem.desktop [ "gnome" "xfce" ]) {
      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        theme = {
          name = "MacTahoe-Dark";
          package = pkgs.mactahoe-gtk;
        };
        gtk2.force = true;
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme =
        lib.mkIf (osConfig.mySystem.desktop == "gnome") "prefer-dark";
    })
  ];
}
