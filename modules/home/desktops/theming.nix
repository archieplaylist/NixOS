# Shared GTK font/icon/cursor for GNOME + XFCE, Alacritty basics for all DEs.
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

    (lib.mkIf (builtins.elem osConfig.mySystem.desktop [ "gnome" "xfce" ]) {
      gtk = {
        enable = true;
        font = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
          size = 10;
        };
        iconTheme = {
          name = "MacTahoe";
          package = pkgs.stdenvNoCC.mkDerivation {
            pname = "mactahoe-icon-theme";
            version = "2026-09-10";
            src = pkgs.fetchFromGitHub {
              owner = "vinceliuice";
              repo = "MacTahoe-icon-theme";
              rev = "2026-09-10";
              hash = "sha256-NAahlBOYub0QlqkYStamoCbyWh+H5JG/iFm4Ws9EU3A=";
            };
            nativeBuildInputs = [ pkgs.bash pkgs.gtk3 ];
            dontBuild = true;
            installPhase = ''
              bash ./install.sh --dest "$out/share/icons" --name MacTahoe --theme default
            '';
          };
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
