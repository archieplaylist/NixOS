# XFCE via home-manager — xfconf XMLs, only when desktop == xfce
{ ... }: {
  config.home.modules.mario = { config, lib, pkgs, osConfig, ... }: let
    orchis-latest = pkgs.orchis-theme.overrideAttrs (old: {
      version = "2026-07-07";
      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "Orchis-theme";
        rev = "2026-07-07";
        hash = "sha256-oX6+tPe0nGsl+OzFZCpbKvE00Z/xvP+NoHY7QZ9YAo0=";
      };
    });
  in
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
      ] ++ [ orchis-latest ];

      # rebuild while logged in: xfconfd caches in RAM, so kill it and reload panel after new XMLs
      home.activation.resetXfconfd = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        xfce_pid=$(${pkgs.procps}/bin/pgrep -u $USER -x xfce4-session || true)
        if [ -n "$xfce_pid" ]; then
          ${pkgs.procps}/bin/pkill -9 -x -u $USER xfconfd || true
          session_env=$(tr '\0' '\n' < "/proc/$xfce_pid/environ" || true)
          display=$(printf '%s\n' "$session_env" | ${pkgs.gnugrep}/bin/grep '^DISPLAY=' | ${pkgs.coreutils}/bin/cut -d= -f2- || true)
          dbus_addr=$(printf '%s\n' "$session_env" | ${pkgs.gnugrep}/bin/grep '^DBUS_SESSION_BUS_ADDRESS=' | ${pkgs.coreutils}/bin/cut -d= -f2- || true)
          if [ -n "$display" ] && [ -n "$dbus_addr" ]; then
            env DISPLAY="$display" DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
              ${pkgs.xfce4-panel}/bin/xfce4-panel -r || true
          fi
        fi
      '';

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
