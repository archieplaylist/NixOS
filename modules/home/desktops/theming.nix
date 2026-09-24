# Shared GTK font/icon/cursor for gnome (Orchis/Tela/Bibata set).
# DE-specific bits (gnome theme + dconf) stay in desktops/.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.desktop == "gnome") {
      gtk = {
        enable = true;
        font = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
          size = 10;
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
      };
    };
}
