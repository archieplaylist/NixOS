# Bash + direnv + ~/.local/bin scripts (yt, tomp3, switch-de)
{ ... }: {
  config.home.modules.mario = {
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
    home.file.".local/bin/gnome-backup" = {
      source = ./scripts/gnome-backup;
      executable = true;
    };
  };
}
