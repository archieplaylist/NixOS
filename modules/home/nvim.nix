# Neovim (LazyVim) — gated on mySystem.appGroups.editor.enable (off on vm).
# The lazy.nvim spec lives in ./nvim/lua as real files, NOT in
# programs.neovim.plugins: that option is a strict Nix-package submodule in
# home-manager 26.05 and rejects lazy.nvim spec tables (it evaluates to
# `option programs.neovim.plugins."..."."LazyVim/LazyVim" does not exist`).
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }:
    lib.mkIf osConfig.mySystem.appGroups.editor.enable {
      programs.neovim = {
        enable = true;
        # NOTE: do NOT set `package = pkgs.neovim`. The default is
        # neovim-unwrapped, and programs.neovim wraps it via wrapNeovimUnstable.
        # Passing the already-wrapped neovim double-wraps it: the inner output's
        # rplugin.vim symlink is copied in by lndir and `touch $out/rplugin.vim`
        # then follows that symlink into a read-only store path and fails with
        # "Permission denied".
        # ./nvim/init.lua is ours; suppress the generated one so the two
        # don't collide on .config/nvim/init.lua
        initLua = lib.mkForce "";
        sideloadInitLua = true;
        defaultEditor = true; # $EDITOR/$VISUAL -> nvim
        viAlias = true; # vi -> nvim
        # HOME-MANAGER BUG: programs.neovim.extraPackages' `--suffix PATH` args
        # get clobbered by the autowrapRuntimeDeps definition, leaving the
        # wrapper empty. nvim-treesitter then can't compile parsers (no cc/make).
        # Pass the args directly instead.
        extraWrapperArgs = lib.mkAfter [
          "--suffix"
          "PATH"
          ":"
          (lib.makeBinPath [ pkgs.gcc pkgs.gnumake ])
        ];
      };

      xdg.configFile."nvim".source = ./nvim;
    };
}
