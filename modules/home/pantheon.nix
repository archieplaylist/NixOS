# Pantheon via dconf — wingpanel/gala/plank, only when desktop == pantheon
{ ... }: {
  config.home.modules.mario = { lib, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.desktop == "pantheon") {
      # ponytail: dconf minimal, plank enabled — gala/wingpanel defaults dari NixOS cukup
      dconf = {
        enable = true;
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Nordic-darker";
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${./assets/wallpaper.png}";
            picture-uri-dark = "file://${./assets/wallpaper.png}";
          };
          "org/pantheon/desktop/gala/appearance" = {
            button-layout = "close:maximize";
          };
          "net/launchpad/plank/docks/dock1" = {
            # ponytail: small dock — 32px, add when bigger needed
            icon-size = 32;
            dock-items = [ "firefox.dockitem" "org.gnome.Terminal.dockitem" "io.elementary.files.dockitem" ];
          };
        };
      };
    };
}
