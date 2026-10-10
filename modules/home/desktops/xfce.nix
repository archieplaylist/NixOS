# primary home xfce: keyring daemon for Electron/Chromium secrets
# (vivaldi, vscode, discord all read org.freedesktop.secrets via libsecret).
# System side (PAM unlock) is in features/desktop.nix; this user daemon
# guarantees the secrets + ssh socket even if PAM races the session,
# same pattern as plasma.nix.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "xfce") {
    home.packages = with pkgs; [
      libsecret # secret-tool for debugging the Login keyring
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
        "commands/custom/Super_L" = "xfce4-popup-whiskermenu";
        "commands/custom/<Super>Return" = "exo-open --launch TerminalEmulator";
        "commands/custom/<Super>space" = "catfish";
      };
    };
  };
}
