# GTK/icon/cursor/font theming — Orchis-Dark / Tela-circle-dark / Bibata (Orchis https://github.com/vinceliuice/Orchis-theme) — ponytail: 26.05 orchis 2025-04-25 ketinggalan, override ke 2026-07-07
{ ... }: {
  config.home.modules.mario = { pkgs, lib, osConfig, ... }:
    let
      orchis-latest = pkgs.orchis-theme.overrideAttrs (old: {
        version = "2026-07-07";
        src = pkgs.fetchFromGitHub {
          owner = "vinceliuice";
          repo = "Orchis-theme";
          rev = "2026-07-07";
          hash = "sha256-oX6+tPe0nGsl+OzFZCpbKvE00Z/xvP+NoHY7QZ9YAo0=";
        };
      });
      isGnome = osConfig.mySystem.desktop == "gnome";
    in
    {
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
          package = orchis-latest;
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

      dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkIf isGnome "prefer-dark";

      home.file.".themes/Orchis-Dark" = {
        source = "${orchis-latest}/share/themes/Orchis-Dark";
      };
    };
}
