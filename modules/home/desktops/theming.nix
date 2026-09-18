# Shared GTK font/icon/cursor for gnome + niri (Orchis/Tela/Bibata set).
# DE-specific bits (gnome theme + dconf, niri pointer cursor) stay in desktops/.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.desktop == "gnome" || osConfig.mySystem.desktop == "niri") {
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
          size = if osConfig.mySystem.desktop == "niri" then 24 else 20;
        };
      };
    };
}
