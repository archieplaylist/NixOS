# Shared GTK / icon / cursor / font theming via home-manager's gtk module
# (GTK2/3 + dconf org.gnome.desktop.interface, incl. color-scheme=dark for
# libadwaita). Chosen set (2026-08-21):
#   theme = Nordic (pkgs.nordic) · icons = Papirus-Dark · cursor =
#   Bibata-Modern-Classic · font = Noto Sans · monospace = JetBrainsMono NF
# Per-DE extras: gnome.nix (shell user-theme), plasma.nix (lookAndFeel),
# xfce.nix (xfconf), lightdm.nix (greeter).
{ ... }: {
  config.home.modules.mario = { pkgs, ... }: {
    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      font = {
        package = pkgs.noto-fonts;
        name = "Noto Sans Reguler";
        size = 10;
      };
      theme = {
        name = "Nordic-darker";
        package = pkgs.nordic;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 20;
      };
      # Overwrite ~/.gtkrc-2.0 without backing up: the gtk module writes the
      # same content every generation, and the leftover .hm-backup otherwise
      # makes home-manager fail with a clobber error on every activation.
      gtk2.force = true;
    };

    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    # Apply the Nordic shell theme via the User Themes extension
    # (user-theme@gnome-shell-extensions.gcampax.github.com is in the enabled
    # extensions list). The extension reads themes from ~/.themes, so link the
    # GNOME Shell variant there.
    home.file.".themes/Nordic" = {
      source = "${pkgs.nordic}/share/themes/Nordic";
    };
  };
}
