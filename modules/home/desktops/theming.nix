# Shared GTK font/icon/cursor for gnome (Orchis/Tela/Bibata set) + alacritty basics for all DEs.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkMerge [
    {
      xdg.configFile."alacritty/alacritty.toml".text = ''
        [window]
        padding = { x = 12, y = 12 }
        opacity = 0.80

        [font]
        size = 11

        [font.normal]
        family = "JetBrainsMono Nerd Font"
      '';
    }

    (lib.mkIf (osConfig.mySystem.desktop == "gnome") {
      gtk = {
        enable = true;
        font = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
          size = 10;
        };
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
        cursorTheme = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 20;
        };
      };
    })
  ];
}
