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

    # MacTahoe-Dark / MacTahoe icons / Bibata
    (lib.mkIf (osConfig.mySystem.desktop == "gnome") {
      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        theme = {
          name = "MacTahoe-Dark";
          package = pkgs.stdenvNoCC.mkDerivation {
            pname = "mactahoe-gtk-theme";
            version = "2026-09-10";
            src = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/1e45e19f510edb8cde18fa84d6cd5319f60b086b/release/MacTahoe-Dark.tar.xz";
              hash = "sha256-COgW5TUiR5VdHPpktErwru53z7xStStPTUvs9lDPXhU=";
            };
            nativeBuildInputs = [ pkgs.xz ];
            dontBuild = true;
            installPhase = ''
              mkdir -p "$out/share/themes/MacTahoe-Dark"
              cp -R . "$out/share/themes/MacTahoe-Dark"
            '';
          };
        };
        gtk2.force = true;
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    })
  ];
}
