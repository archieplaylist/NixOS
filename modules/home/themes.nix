# GTK/icon/cursor/font theming — Orchis-Dark / Tela-circle-dark / Bibata (Orchis https://github.com/vinceliuice/Orchis-theme)
{ ... }: {
  config.home.modules.mario = { pkgs, ... }: {
    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      font = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
        size = 10;
      };
      theme = {
        name = "Orchis-Dark";
        package = pkgs.orchis-theme;
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
      gtk2.force = true;
    };

    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    home.file.".themes/Orchis-Dark" = {
      source = "${pkgs.orchis-theme}/share/themes/Orchis-Dark";
    };
  };
}
