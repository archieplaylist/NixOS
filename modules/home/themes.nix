# WhiteSur dark theme (GTK), icons and cursor. home-manager's `gtk` module
# installs the packages, writes ~/.config/gtk-3.0/settings.ini, and sets
# org.gnome.desktop.interface in dconf (including color-scheme=prefer-dark
# for libadwaita apps).
{ ... }: {
  config.home.modules.mario = { pkgs, ... }: {
    gtk = {
      enable = true;
      colorScheme = "dark";
      theme = {
        name = "WhiteSur-Dark";
        package = pkgs.whitesur-gtk-theme;
      };
      iconTheme = {
        name = "WhiteSur-dark";
        package = pkgs.whitesur-icon-theme;
      };
      cursorTheme = {
        name = "WhiteSur-cursors";
        package = pkgs.whitesur-cursors;
      };
      # Overwrite ~/.gtkrc-2.0 without backing up: the gtk module writes the
      # same content every generation, and the leftover .hm-backup otherwise
      # makes home-manager fail with a clobber error on every activation.
      gtk2.force = true;
    };

    # Apply the WhiteSur-dark shell theme via the User Themes extension
    # (user-theme@gnome-shell-extensions.gcampax.github.com is in the enabled
    # extensions list). The extension reads themes from ~/.themes and
    # ~/.local/share/themes, so link the GNOME Shell variant there.
    home.file.".themes/WhiteSur-Dark" = {
      source = "${pkgs.whitesur-gtk-theme}/share/themes/WhiteSur-Dark";
    };
  };
}
