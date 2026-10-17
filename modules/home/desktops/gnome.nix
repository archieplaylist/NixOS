# primary home gnome: dconf settings, GTK/icon/cursor/font theming
# (Orchis-Dark for gnome, Ayu-Dark for xfce — set per-DE below).
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

    # GTK theme is per-DE, set in the blocks below; shared bits:
    # fonts/icons/cursor live in theming.nix. Both DEs get dark preference.
    (lib.mkIf (builtins.elem osConfig.mySystem.desktop [ "gnome" "xfce" ]) {
      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk2.force = true;
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme =
        lib.mkIf (osConfig.mySystem.desktop == "gnome") "prefer-dark";
    })

    (lib.mkIf (osConfig.mySystem.desktop == "gnome") {
      # gnome keeps the riced Orchis-Dark shell theme
      gtk.theme = {
        name = "Orchis-Dark";
        package = pkgs.unstable.orchis-theme;
      };
    })

    # Ayu for Xfce — GTK/xfwm4 theme used by xfconf.settings in
    # xfce.nix; nixpkgs ayu-theme-gtk ships gtk-2/3 + xfwm4 assets
    (lib.mkIf (osConfig.mySystem.desktop == "xfce") {
      gtk.theme = {
        name = "Ayu-Dark";
        package = pkgs.ayu-theme-gtk;
      };
    })
  ];
}
