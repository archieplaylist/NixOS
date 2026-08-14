# Git user setup plus a global exclude file. git reads
# $XDG_CONFIG_HOME/git/ignore automatically, so these patterns apply to every
# repo on this machine (unlike a ~/.gitignore, which git never consults
# unless the root of the repo happens to be $HOME).
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
