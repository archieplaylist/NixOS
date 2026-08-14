# Shell: bash aliases, direnv, and the user scripts `yt` / `tomp3`.
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

    # `yt` and `tomp3` live as plain bash scripts (no Nix string escaping, easy
    # to test) in ~/.local/bin, which is put on PATH via home.sessionPath
    # (modules/home/user.nix).
    home.file.".local/bin/yt" = {
      source = ./scripts/yt;
      executable = true;
    };
    home.file.".local/bin/tomp3" = {
      source = ./scripts/tomp3;
      executable = true;
    };
  };
}
