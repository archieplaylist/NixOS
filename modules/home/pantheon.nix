# Pantheon via dconf — wingpanel/gala/plank, only when desktop == pantheon
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.desktop == "pantheon") {
      # ponytail: tema default dark pantheon (io.elementary.stylesheet.blueberry + elementary icons), override Nordic dari themes.nix
      gtk.theme = {
        name = lib.mkForce "io.elementary.stylesheet.blueberry";
        package = lib.mkForce pkgs.pantheon.elementary-gtk-theme;
      };
      gtk.iconTheme = {
        name = lib.mkForce "elementary";
        package = lib.mkForce pkgs.pantheon.elementary-icon-theme;
      };
      gtk.cursorTheme = {
        name = lib.mkForce "elementary";
        package = lib.mkForce pkgs.pantheon.elementary-icon-theme;
      };

      dconf = {
        enable = true;
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "io.elementary.stylesheet.blueberry";
            icon-theme = "elementary";
            cursor-theme = "elementary";
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${./assets/wallpaper.png}";
            picture-uri-dark = "file://${./assets/wallpaper.png}";
          };
          "org/pantheon/desktop/gala/appearance" = {
            button-layout = "close:minimize,maximize";
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
