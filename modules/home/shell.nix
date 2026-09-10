# Bash + direnv + ~/.local/bin scripts (yt, tomp3, switch-de, backup-de)
_: {
  config.home.modules.mario = { lib, osConfig, ... }: {
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
  };
}
