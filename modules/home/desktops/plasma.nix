# primary home plasma: kate + alacritty basics (Plasma ships its own apps and
# theming — set in System Settings, no declarative config, xfce precedent).
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "plasma") {
    home.packages = with pkgs; [
      kdePackages.kate
    ];

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
