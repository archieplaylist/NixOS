# mario home — identity + XDG/session (other modules merge into same slot)
_: {
  config.home.modules.mario = { lib, osConfig, ... }: {
    home = {
      username = "mario";
      homeDirectory = "/home/mario";
      stateVersion = "26.05";
    };

    # ponytail: SSH_AUTH_SOCK only for gnome-keyring DEs — plasma uses kwallet, no relogin prompt
    home.sessionVariables = lib.mkMerge [
      {
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CACHE_HOME = "$HOME/.cache";
      }
      (lib.mkIf (osConfig.mySystem.desktop != "plasma") {
        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
      })
    ];

    xdg.userDirs = {
      enable = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      templates = "$HOME/Templates";
      publicShare = "$HOME/Public";
      createDirectories = true;
      extraConfig = {
        XDG_PROJECTS_DIR = "$HOME/Projects";
      };
    };

    home.sessionPath = [ "$HOME/.local/bin" ];
  };
}
