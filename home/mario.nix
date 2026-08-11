# Entry point for mario's home-manager config (imported by flake.nix).
# Submodules cover one concern each:
#   shell.nix   bash aliases, direnv, custom scripts (yt, tomp3)
#   apps.nix    user packages, gated on mySystem.appGroups.*
#   fastfetch.nix  fastfetch config (~/.config/fastfetch)
#   gnome.nix   GNOME dconf settings (extensions, theme, tweaks)
#   themes.nix  WhiteSur dark GTK/icon/cursor theme
#   tooling.nix git config + global excludes
{ ...
}: {
  imports = [
    ./apps.nix
    ./fastfetch.nix
    ./gnome.nix
    ./shell.nix
    ./themes.nix
    ./tooling.nix
  ];

  home = {
    username = "mario";
    homeDirectory = "/home/mario";
    stateVersion = "26.05";
  };

  # Explicit XDG layout: app config -> ~/.config, data -> ~/.local/share,
  # mutable state -> ~/.local/state, caches -> ~/.cache. Keeps the list of
  # things worth persisting short (3 dirs) instead of per-app paths.
  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_CACHE_HOME = "$HOME/.cache";
  };

  # ~/.local/bin holds user scripts (yt, tomp3 — see shell.nix). Put it on
  # PATH for the session, independent of NixOS defaults.
  home.sessionPath = [ "$HOME/.local/bin" ];
}