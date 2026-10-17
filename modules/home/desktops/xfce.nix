# primary home xfce: keyring daemon for Electron/Chromium secrets
# (vivaldi, vscode, discord all read org.freedesktop.secrets via libsecret).
# System side (PAM unlock) is in features/desktop.nix; this user daemon
# guarantees the secrets + ssh socket even if PAM races the session,
# same pattern as plasma.nix.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "xfce") {
    home.packages = with pkgs; [
      libsecret # secret-tool for debugging the Login keyring
      polybar # replaces xfce4-panel, see polybar-start + autostart below
      rofi # Super_L launcher, replaces whiskermenu
      wmctrl # dock taskbar: window list + click-to-focus
      xdotool # dock taskbar: window activate/close actions
      xorg.xprop # dock taskbar: focused-window property
    ];

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };
    home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";

    # Mirror the shared Orchis-Dark GTK theming (theming.nix + gnome.nix write
    # gtk.ini, but Xfce reads the xsettings channel) so Thunar/mousepad
    # match GNOME. programs.xfconf is already on via the NixOS xfce module.
    xfconf.settings = {
      xsettings = {
        "Net/ThemeName" = "Orchis-Dark-Compact";
        "Net/IconThemeName" = "MacTahoe-dark";
        "Gtk/FontName" = "Noto Sans 10";
        "Gtk/MonospaceFontName" = "JetBrainsMono Nerd Font 11";
        "Gtk/CursorThemeName" = "Bibata-Modern-Classic";
        "Gtk/CursorThemeSize" = 20;
      };
      xfwm4 = {
        "general/theme" = "Orchis-Dark-Compact";
      };
      xfce4-keyboard-shortcuts = {
        "commands/custom/override" = true;
        "commands/custom/Super_L" = "rofi -show drun";
        "commands/custom/<Super>Return" = "exo-open --launch TerminalEmulator";
        "commands/custom/<Super>space" = "catfish";
      };
    };

    # Keys + rofi launcher; polybar takes over the panel + tray. Configs are
    # the standard polybar/rofi paths polybar reads without -c flags.
    xdg.configFile."polybar/config.ini".source = ./xfce/polybar.ini;
    xdg.configFile."rofi/config.rasi".source = ./xfce/rofi.rasi;
    xdg.configFile."polybar/dock-icons.sh" = {
      source = ./xfce/dock-icons.sh;
      executable = true;
    };
    xdg.configFile."polybar/taskbar.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Clickable icon-per-window list for the bottom dock: click focuses
        # the window, right-click closes it. Kills poll via wmctrl each
        # polybar update tick (interval=1). Glyphs verified in
        # JetBrainsMono Nerd Font; titles %-escaped for polybar markup.
        WMC="${pkgs.wmctrl}/bin/wmctrl"
        XPR="${pkgs.xorg.xprop}/bin/xprop"
        XDO="${pkgs.xdotool}/bin/xdotool"

        active=$("$XPR" -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $5}')
        "$WMC" -l -x 2>/dev/null | while read -r id desk host class title; do
          c=$(
            echo "$class" | tr '[:upper:]' '[:lower:]'
          )
          case "$c" in
            *polybar*) continue ;;
          esac
          case "$c" in
            *term* | *alacritty* | *xterm*) glyph=$(printf '\ue795') ;;
            *firefox* | *chrom* | *vivaldi* | *brave*) glyph=$(printf '\uf269') ;;
            *thunar* | *pcmanfm* | *nautilus* | *ranger* | *nemo*) glyph=$(printf '\uf07b') ;;
            *code* | *jetbrains* | *vim* | *neovim*) glyph=$(printf '\ue70c') ;;
            *) glyph=$(printf '\U000F0768') ;;
          esac
          # polybar reads % as token start — escape titles
          esc=$(
            printf '%s' "$title" | sed 's/%/%%/g'
          )
          if [ "$id" = "$active" ]; then
            fg='%{F#e6b450}%{B#141821}'
          else
            fg='%{F-}%{B-}'
          fi
          echo -n "$fg%{A1:$WMC -ia $id:}%{A3:$XDO windowclose $id:} $glyph $esc %{A}%{A}"
        done
        echo
      '';
      executable = true;
    };

    home.file.".local/bin/polybar-start".text = ''
      #!/usr/bin/env bash
      # XFCE autostart fallback: features/desktop.nix also shadows
      # bin/xfce4-panel on PATH so the session manager's panel spawns land
      # in the same shim — this covers brand-new sessions without a panel
      # client. Two bars: main (top) + dock (bottom). Whatever starts last
      # wins; both kill the other first.
      pkill -x polybar 2>/dev/null
      ${pkgs.polybar}/bin/polybar main >/dev/null 2>&1 &
      ${pkgs.polybar}/bin/polybar dock >/dev/null 2>&1 &
      wait
    '';
    home.file.".local/bin/polybar-start".executable = true;

    xdg.configFile."autostart/polybar.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Polybar
      Exec=/home/${osConfig.mySystem.username}/.local/bin/polybar-start
      NoDisplay=true
      X-Order=-100
    '';
  };
}
