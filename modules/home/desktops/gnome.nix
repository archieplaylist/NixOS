# primary home gnome: dconf settings, GTK/icon/cursor/font theming
# (Ayu-Dark GTK + GNOME Shell theme for every DE; Orchis stays installed
# so it can be picked again in gnome-tweaks).
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
            name = "Ayu-Dark";
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

    # Shared GTK bits for both DEs; fonts/icons/cursor live in theming.nix.
    # Both DEs get dark preference.
    (lib.mkIf (builtins.elem osConfig.mySystem.desktop [ "gnome" "xfce" ]) {
      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk2.force = true;
        # Ayu-Dark (transparent) everywhere; the package is also installed
        # system-wide (features/desktop.nix) so xfwm4 and the greeter see it
        theme = {
          name = "Ayu-Dark";
          package = pkgs.ayu-theme;
        };
        # libadwaita apps only read ~/.config/gtk-4.0/gtk.css — home-manager
        # imports the theme CSS there (gtk4 theme is opt-in since HM 26.05),
        # these named colors recolor the rest
        gtk4.theme = {
          name = "Ayu-Dark";
          package = pkgs.ayu-theme;
        };
        gtk4.extraCss = builtins.readFile "${pkgs.ayu-theme}/share/ayu-theme/libadwaita/gtk.css.dark";
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme =
        lib.mkIf (osConfig.mySystem.desktop == "gnome") "prefer-dark";
    })

    # Orchis is no longer the active theme but stays installed so it can be
    # selected again in gnome-tweaks without rebuilding the config
    (lib.mkIf (osConfig.mySystem.desktop == "gnome") {
      home.packages = [ pkgs.unstable.orchis-theme ];
    })
  ];
}
