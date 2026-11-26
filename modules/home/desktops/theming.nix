# Shared GTK font/icon/cursor for GNOME + XFCE.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.enableDesktop && builtins.elem osConfig.mySystem.desktop [ "gnome" "xfce" ]) {
      gtk = {
        enable = true;
        font = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
          size = 10;
        };
        iconTheme = {
          name = "MacTahoe";
          package = pkgs.mactahoe-icons;
        };
        cursorTheme = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 20;
        };
      };
    };
}
