# mario's home-manager entry. Every home feature module (apps, fastfetch,
# gnome, shell, themes, tooling) merges into this single slot; this file holds
# only the user identity and the shared session/XDG settings.
{ ... }: {
  config.home.modules.mario = {
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
  };
}
