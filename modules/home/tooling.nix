# Git config + global excludes (applies via $XDG_CONFIG_HOME/git/ignore)
{ ... }: {
  config.home.modules.mario = {
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
  };
}
