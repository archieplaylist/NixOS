{ config
, lib
, pkgs
, ...
}: {
  options = {
    myApps = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable general-purpose applications (browsers, media, gaming).";
      };
    };
  };

  config = {
    home = {
      username = "mario";
      homeDirectory = "/home/mario";
      stateVersion = "26.05";
    };

    # Base dotfile.
    home.file.".gitignore".text = ''
      result
      .direnv
      .cache
      node_modules
    '';

    # --- Shell ---------------------------------------------------------------
    programs.bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ls = "ls --color=auto";
        ll = "ls -lha";
        grep = "grep --color=auto";
      };
    };

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    # --- Tooling ---------------------------------------------------
    programs.git = {
      enable = true;
      settings = {
        user.name = "archieplaylist";
        user.email = "mario.tani25@gmail.com";
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
      };
    };

    # User-level packages.
    home.packages = lib.mkMerge [
      (with pkgs; [
        vscode
        python3
        nodejs_24
        gh
        docker-compose
        jq
        yq
        fzf
        bat
        eza
      ])
      # General-purpose applications (browsers, media, gaming). Disabled per
      # host with `home-manager.users.mario.myApps.enable = false`.
      (lib.mkIf config.myApps.enable (with pkgs; [
        firefox
        chromium
        vivaldi
        vlc
        mpv
        mangohud
        gamescope
        heroic
      ]))
    ];
  };
}
