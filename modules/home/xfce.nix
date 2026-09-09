# XFCE via home-manager — xfconf XMLs, only when desktop == xfce
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
        tela-circle-icon-theme
        orchis-theme
      ];

      xdg.configFile = {
        "kitty/kitty.conf" = {
          source = ./assets/kitty/kitty.conf;
        };

        # panel: single bottom + whiskermenu (force=true so declarative wins over xfconfd runtime writes)
        "xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" = {
          force = true;
          source = ./assets/xfce/xfce4-panel.xml;
        };

        # shortcuts: Super->whiskermenu, Alt+Space->appfinder, Super+L->lock (override=true required)
        "xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" = {
          force = true;
          source = ./assets/xfce/xfce4-keyboard-shortcuts.xml;
        };

        "xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" = {
          force = true;
          source = ./assets/xfce/xfwm4.xml;
        };

        "xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" = {
          force = true;
          source = ./assets/xfce/xsettings.xml;
        };

        "xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml" = {
          force = true;
          source = ./assets/xfce/xfce4-screensaver.xml;
        };

        # touchpad natural scroll — xfsettingsd expects SynPS2_Synaptics_TouchPad + ReverseScrolling
        "xfce4/xfconf/xfce-perchannel-xml/pointers.xml" = {
          force = true;
          source = ./assets/xfce/pointers.xml;
        };

        # xfdesktop disabled icons + wallpaper wallpapers per output (eDP-1/HDMI/DP-1 + VM Virtual-1/VBOX0)
        "xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" = {
          force = true;
          source = pkgs.writeText "xfce4-desktop.xml"
            (builtins.replaceStrings
              [ "@WALLPAPER@" ]
              [ "${./assets/wallpaper.png}" ]
              (builtins.readFile ./assets/xfce/xfce4-desktop.xml));
        };
      };
    };
}
