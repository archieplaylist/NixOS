# Stylix now owns GTK/icon/cursor theming (modules/features/stylix.nix).
# This file is kept as a no-op so `gtk` is not double-managed. Stylix writes
# ~/.config/gtk-3.0/settings.ini and dconf (color-scheme=prefer-dark for
# libadwaita) plus exposes the theme to Flatpaks via `gtk.flatpakSupport`.
# To fork GTK away from Stylix, set `stylix.targets.gtk.enable = false` in
# home.modules.mario and re-add a `gtk` block here. The old WhiteSur block is
# archived below for reference.
{ ... }: { config.home.modules.mario = { ... }: { }; }
