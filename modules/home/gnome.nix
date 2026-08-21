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
        # Stylix manages GNOME theming via stylix.targets.gnome (user-theme
        # "Stylix", background, color-scheme, fonts). It does NOT own the
        # enabled-extensions list — that stays as single source
        # `mySystem.gnomeExtensions` (see desktop.nix). The two now coexist:
        # Stylix writes theme/background, this module writes extensions + prefs.
        "org/gnome/shell" = {
          enabled-extensions = map (e: e.uuid) osConfig.mySystem.gnomeExtensions;
        };
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
