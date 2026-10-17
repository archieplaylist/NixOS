# primary home xfce: keyring daemon for Electron/Chromium secrets
# (vivaldi, vscode, discord all read org.freedesktop.secrets via libsecret).
# System side (PAM unlock) is in features/desktop.nix; this user daemon
# guarantees the secrets + ssh socket even if PAM races the session,
# same pattern as plasma.nix.
#
# Bar = eww (replaces polybar, 2026-10): gross search/powermenu/appbar +
# Saimoomedits bar widgets, merged + ayu-recolored in ./xfce/eww/. Gross is not a
# rofi theme — the whole launcher is the gross search widget now (Super_L).
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "xfce") (let
    # stalonetray anchors bottom-right like the old polybar tray-position; eww
    # has no native systray, gross/polybar both just left tray icons dead.
    stalonetrayrc = pkgs.writeText "stalonetrayrc" ''
      geometry 1x1-2-2
      icon_size 18
      sticky true
      window_position none
      background "#0d1017d9"
      icon_theme "MacTahoe-dark"
    '';
  in {
    home.packages = with pkgs; [
      libsecret # secret-tool for debugging the Login keyring
      eww # gross widgets + bar, replaces polybar + rofi
      brightnessctl # bar brightness scale (laptop backlight)
      stalonetray # systray — eww has no native tray (nm-applet etc.)
      wmctrl # workspace probe + gross fetch `wm` var
      xdotool # gross search window focus
    ];

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };
    home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";

    # Mirror the Ayu-Dark GTK theming (gnome.nix sets gtk.theme for xfce) so
    # Thunar/mousepad match the ayu eww bar + gross widgets. Xfce reads the
    # xsettings channel; programs.xfconf is already on via the NixOS xfce module.
    xfconf.settings = {
      xsettings = {
        "Net/ThemeName" = "Ayu-Dark";
        "Net/IconThemeName" = "MacTahoe-dark";
        "Gtk/FontName" = "Noto Sans 10";
        "Gtk/MonospaceFontName" = "JetBrainsMono Nerd Font 11";
        "Gtk/CursorThemeName" = "Bibata-Modern-Classic";
        "Gtk/CursorThemeSize" = 20;
      };
      xfwm4 = {
        "general/theme" = "Ayu-Dark";
      };
      xfce4-keyboard-shortcuts = {
        "commands/custom/override" = true;
        # gross searchapps widget replaces rofi's drun
        "commands/custom/Super_L" = "eww open searchapps";
        # gross bigpowermenu panel
        "commands/custom/<Super>q" = "$HOME/.config/eww/scripts/powermenu-toggle.sh";
        "commands/custom/<Super>Return" = "exo-open --launch TerminalEmulator";
        "commands/custom/<Super>space" = "catfish";
      };
    };

    # Keys + gross launcher; eww takes over panel + bar duties. Configs live at
    # the standard ~/.config/eww path eww reads with no -c flags.
    xdg.configFile."eww/eww.yuck".source = ./xfce/eww/eww.yuck;
    xdg.configFile."eww/eww_variables.yuck".source = ./xfce/eww/eww_variables.yuck;
    xdg.configFile."eww/eww_widgets.yuck".source = ./xfce/eww/eww_widgets.yuck;
    xdg.configFile."eww/bar.yuck".source = ./xfce/eww/bar.yuck;
    xdg.configFile."eww/eww_windows.yuck".source = ./xfce/eww/eww_windows.yuck;
    xdg.configFile."eww/eww.scss".source = ./xfce/eww/eww.scss;
    xdg.configFile."eww/scripts" = {
      source = ./xfce/eww/scripts;
      recursive = true;
      executable = true;
    };

    home.file.".local/bin/eww-start".text = ''
      #!/usr/bin/env bash
      # XFCE autostart fallback: features/desktop.nix also shadows
      # bin/xfce4-panel on PATH so the session manager's panel spawns land
      # in the same shim — this covers brand-new sessions without a panel
      # client. Bar + gross appbar dock; gross search on Super_L, powermenu
      # on Super+q.
      pkill -x eww 2>/dev/null
      ${pkgs.stalonetray}/bin/stalonetray --config ${stalonetrayrc} >/dev/null 2>&1 &
      ${pkgs.eww}/bin/eww daemon >/dev/null 2>&1 &
      # daemon needs a beat to bind its socket; retry so a slow first open
      # doesn't leave the session bar-less
      for i in 1 2 3 4 5; do
        sleep 1
        ${pkgs.eww}/bin/eww open bar && break
      done
      ${pkgs.eww}/bin/eww open appbar >/dev/null 2>&1
      # seed the gross search list so the defpoll doesn't cat a missing file
      mkdir -p ~/.local/state/eww
      ~/.config/eww/scripts/search.sh &>/dev/null
      wait
    '';
    home.file.".local/bin/eww-start".executable = true;

    xdg.configFile."autostart/eww.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=eww
      Exec=/home/${osConfig.mySystem.username}/.local/bin/eww-start
      NoDisplay=true
      X-Order=-100
    '';
  });
}
