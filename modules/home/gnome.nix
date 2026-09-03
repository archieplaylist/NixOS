# GNOME dconf — extension list from mySystem.gnomeExtensions, only on gnome hosts
_: {
  config.home.modules.mario = { lib, osConfig, ... }: {
    dconf = {
      enable = true;
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
  };
}
