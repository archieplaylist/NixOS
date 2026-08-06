{
  config,
  lib,
  pkgs,
  ...
}: {
  home = {
    username = "mario";
    homeDirectory = "/home/mario";
    stateVersion = "24.11";
  };

  # Base dotfile.
  home.file.".gitignore".text = ''
    result
    .direnv
    .cache
    node_modules
  '';

  # --- Shell -----------------------------------------------------------------
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

  # --- Tooling ---------------------------------------------------------------
  programs.git = {
    enable = true;
    userName = "mario";
    userEmail = "mario@example.com";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  # User-level packages.
  home.packages = with pkgs; [
    vscode
    python3
    nodejs_22
    go
    rustup
    gh
    docker-compose
    jq
    yq
    fzf
    bat
    eza
  ];
}