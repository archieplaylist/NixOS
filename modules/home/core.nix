# mario home core: identity/XDG (user), bash/direnv/scripts (shell),
# git (tooling), fastfetch config. Sections merged, behavior unchanged.
_: {
  config.home.modules.mario = { lib, osConfig, ... }: lib.mkMerge [
    {
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
        } // lib.optionalAttrs (osConfig.mySystem.hostname == "central8") {
          # ponytail: work-only websvr docker recycle — folder exists only on central8
          websvr-restart = "cd ~/Documents/test-folder/websvr && sudo systemctl restart docker && sleep 3 && sudo docker compose down && sleep 3 && sudo docker compose up -d";
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
    }

    {
      programs.git = {
        enable = true;
        settings = {
          user.name = "archieplaylist";
          user.email = "archieplaylist@users.noreply.github.com";
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
