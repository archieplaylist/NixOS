# primary home cinnamon: alacritty basics (Cinnamon ships nemo + its own apps
# and theming — set in System Settings, no declarative config).
_: {
  config.home.modules.primary = { lib, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "cinnamon") {
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
