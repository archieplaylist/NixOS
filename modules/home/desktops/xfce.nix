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
      # polybar owns the bar; reset the user-saved panel layout on every HM
      # activation so it falls through to the system-wide empty default
      # (features/desktop.nix /etc/xfconf file) and the panel stays blank
      "xfce4-panel" = {
        "panels" = null;
      };
    };

    # Keys + rofi launcher; polybar takes over the panel + tray. Configs are
    # the standard polybar/rofi paths polybar reads without -c flags.
    xdg.configFile."polybar/config.ini".source = ./xfce/polybar.ini;
    xdg.configFile."rofi/config.rasi".source = ./xfce/rofi.rasi;

    home.file.".local/bin/polybar-start".text = ''
      #!/usr/bin/env bash
      # XFCE autostart: start the bar; xfce4-panel is neutralized
      # declaratively (empty /panels xfconf default in features/desktop.nix +
      # the panels reset above), so no panel killing is needed here.
      killall -q polybar
      exec ${pkgs.polybar}/bin/polybar main
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
