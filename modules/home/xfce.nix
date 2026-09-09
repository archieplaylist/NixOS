# XFCE via home-manager — stock defaults, only when desktop == xfce
_: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.desktop == "xfce") {
      home.packages = with pkgs; [
        kitty
        xfce4-terminal
        xfce4-screenshooter
        xfce4-clipman-plugin
        xfce4-whiskermenu-plugin
        xfce4-power-manager
        xfce4-appfinder
        mousepad
        seahorse
        # ponytail: packages only, no declarative config — set manually in Appearance
        orchis-theme
        tela-circle-icon-theme
        bibata-cursors
      ];
    };
}
