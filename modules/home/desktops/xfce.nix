# primary home xfce: keyring daemon for Electron/Chromium secrets
# (vivaldi, vscode, discord all read org.freedesktop.secrets via libsecret).
# System side (PAM unlock) is in features/desktop.nix; this user daemon
# guarantees the secrets + ssh socket even if PAM races the session,
# same pattern as plasma.nix.
#
# Bar = stock xfce4-panel (eww/gross removed 2026-10). Panel layout is
# user-owned xfconf state — nothing declared here touches it.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "xfce") {
    home.packages = with pkgs; [
      libsecret # secret-tool for debugging the Login keyring
      brightnessctl # laptop backlight
    ];

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };
    home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";

    # Mirror the Ayu-Dark GTK theming (gnome.nix sets gtk.theme) so
    # Thunar/mousepad/panel match. The theme ships gtk-2/3/4 + xfwm4
    # assets and is installed system-wide (features/desktop.nix).
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
        # pop the whiskermenu off the panel (was gross searchapps)
        "commands/custom/Super_L" = "xfce4-popup-whiskermenu";
        "commands/custom/<Super>Return" = "exo-open --launch TerminalEmulator";
        "commands/custom/<Super>space" = "catfish";
      };
    };
  };
}
