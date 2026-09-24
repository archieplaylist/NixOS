# primary home plasma: kate + alacritty basics (Plasma ships its own apps and
# theming — set in System Settings, no declarative config).
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "plasma") {
    home.packages = with pkgs; [
      kdePackages.kate
      qt6Packages.qtstyleplugin-kvantum # Qt6 Kvantum style + Manager, pick theme in System Settings
    ];

    # SDDM PAM unlock alone leaves no daemon in Plasma session (same flakiness as ly) — user daemon guarantees secrets+ssh socket
    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };
    home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";

    xdg.configFile."alacritty/alacritty.toml".text = ''
      [window]
      padding = { x = 12, y = 12 }
      opacity = 0.80

      [font]
      size = 11

      [font.normal]
      family = "JetBrainsMono Nerd Font"
    '';
  };
}
