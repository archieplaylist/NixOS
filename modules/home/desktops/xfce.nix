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
  };
}
