# GNOME dconf settings. The extension list is pinned by writing it directly
# into the user's dconf database; the list itself lives in one place — the
# mySystem.gnomeExtensions option (see modules/system/options.nix), with the
# system-level packages and GSettings defaults derived from it in desktop.nix.
{ osConfig
, ...
}: {
  dconf = {
    enable = true;
    settings."org/gnome/shell" = {
      enabled-extensions = map (e: e.uuid) osConfig.mySystem.gnomeExtensions;
    };
    # User Themes extension: apply the WhiteSur-dark shell theme from
    # ~/.themes (linked in themes.nix).
    settings."org/gnome/shell/extensions/user-theme" = {
      name = "WhiteSur-Dark";
    };
    # Titlebar buttons: minimize, maximize and close on the right.
    settings."org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    # Middle-click pastes the primary selection.
    settings."org/gnome/desktop/interface" = {
      gtk-enable-primary-paste = true;
    };
    # Overamplification: allow volume above 100%.
    settings."org/gnome/desktop/sound" = {
      allow-volume-above-100-percent = true;
    };
  };
}