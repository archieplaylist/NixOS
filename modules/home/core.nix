# primary home core: identity/XDG (user), bash/direnv/scripts (shell),
# git (tooling), fastfetch config. Sections merged, behavior unchanged.
_: {
  config.home.modules.primary = { lib, osConfig, ... }: lib.mkMerge [
    {
      home = {
        username = osConfig.mySystem.username;
        homeDirectory = "/home/${osConfig.mySystem.username}";
        stateVersion = "26.05";
      };

      # all DEs share gnome-keyring now, one Login keyring, no relogin
      # SSH_AUTH_SOCK is set per-DE where a keyring ssh agent is guaranteed to run
      home.sessionVariables = {
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CACHE_HOME = "$HOME/.cache";
      };

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
    }

    {
      programs.bash = {
        enable = true;
        enableCompletion = true;
        shellAliases = {
          ls = "ls --color=auto";
          ll = "ls -lha";
          grep = "grep --color=auto";
          ff = "fastfetch";
        };
      };

      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };

      home.file.".local/bin/yt" = {
        source = ./scripts/yt;
        executable = true;
      };
      home.file.".local/bin/tomp3" = {
        source = ./scripts/tomp3;
        executable = true;
      };
      home.file.".local/bin/switch-de" = {
        source = ./scripts/switch-de;
        executable = true;
      };
      home.file.".local/bin/backup-de" = {
        source = ./scripts/backup-de;
        executable = true;
      };
      # shared DE path lists, sourced by switch-de + backup-de
      home.file.".local/bin/de-paths" = {
        source = ./scripts/de-paths;
      };
    }

    # sunshine/tailscale toggle — only where the sunshine host is enabled
    (lib.mkIf osConfig.mySystem.enableSunshine {
      home.file.".local/bin/stream" = {
        source = ./scripts/stream;
        executable = true;
      };
    })

    {
      programs.git = {
        enable = true;
        settings = {
          user.name = osConfig.mySystem.gitName;
          user.email = osConfig.mySystem.gitEmail;
          init.defaultBranch = "main";
          push.autoSetupRemote = true;
        };
      };

      xdg.configFile."git/ignore".text = ''
        result
        .direnv
        .cache
        node_modules
      '';
    }

    # fastfetch config — package installed via apps.nix
    {
      xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch/config.jsonc;
    }
  ];
}
