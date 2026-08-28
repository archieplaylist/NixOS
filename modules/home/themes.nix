# GTK/icon/cursor/font theming — Qogir-dark / Qogir-dark / Bibata (Qogir https://www.gnome-look.org/p/1230631)
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
        name = "Qogir-dark";
        package = pkgs.qogir-theme;
      };
      iconTheme = {
        name = "Qogir-dark";
        package = pkgs.qogir-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 20;
      };
      gtk2.force = true;
    };

    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    home.file.".themes/Qogir-dark" = {
      source = "${pkgs.qogir-theme}/share/themes/Qogir-dark";
    };
  };
}
