# GNOME dconf settings. The extension list is pinned by writing it directly
# into the user's dconf database; the list itself lives in one place — the
# mySystem.gnomeExtensions option (see modules/features/mySystem.nix), with the
# system-level packages and GSettings defaults derived from it in desktop.nix.
# Only applied when this host runs GNOME (mySystem.desktop == "gnome"), so a
# switch to Plasma hands the dconf database over to the switch-de script.
{ ... }: {
  config.home.modules.mario = { lib, osConfig, ... }: {
    dconf = {
      enable = true;
      settings = lib.mkIf (osConfig.mySystem.desktop == "gnome") {
        "org/gnome/shell" = {
          enabled-extensions = map (e: e.uuid) osConfig.mySystem.gnomeExtensions;
        };
        # User Themes extension: apply the Nordic shell theme from ~/.themes
        # (linked in themes.nix).
        "org/gnome/shell/extensions/user-theme" = {
          name = "Nordic";
        };
        # Titlebar buttons: minimize, maximize and close on the right.
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };
        # Middle-click pastes the primary selection.
        # font-name is owned by themes.nix (gtk.font = Noto Sans 10); don't
        # duplicate it here — gtk3.nix writes the same dconf key and would
        # conflict (10 vs 11). Keep monospace/document here (gtk module doesn't set them).
        "org/gnome/desktop/interface" = {
          gtk-enable-primary-paste = true;
          monospace-font-name = "JetBrainsMono Nerd Font 11";
          document-font-name = "Noto Sans 11";
        };
        # Overamplification: allow volume above 100%.
        "org/gnome/desktop/sound" = {
          allow-volume-above-100-percent = true;
        };
        # Wallpaper: the shared repo image (same one XFCE and Plasma use).
        # Both URIs are set because the theme stack pins the dark preference,
        # and GNOME reads picture-uri-dark when color-scheme is prefer-dark.
        "org/gnome/desktop/background" = {
          picture-uri = "file://${./assets/wallpaper.png}";
          picture-uri-dark = "file://${./assets/wallpaper.png}";
          picture-options = "zoom";
        };
      };
    };
  };
}
