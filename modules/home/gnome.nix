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
        # User Themes extension: Stylix now manages the shell theme
        # (stylix.targets.gnome). Keep the key so `user-themes` extension
        # stays enabled; Stylix writes the actual theme name.
        # "org/gnome/shell/extensions/user-theme".name is set by Stylix.
        # Titlebar buttons: minimize, maximize and close on the right.
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };
        # Middle-click pastes the primary selection.
        "org/gnome/desktop/interface" = {
          gtk-enable-primary-paste = true;
        };
        # Overamplification: allow volume above 100%.
        "org/gnome/desktop/sound" = {
          allow-volume-above-100-percent = true;
        };
      };
    };
  };
}
