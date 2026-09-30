local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim itself
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- extras + any custom specs live in lua/plugins/
    { import = "plugins" },
  },
  -- This config dir is a symlink into the read-only /nix/store, so lazy.nvim
  -- cannot write lazy-lock.json there. Keep it in XDG_STATE_HOME instead.
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
  -- notify about plugin updates
  checker = { enabled = true },
  install = { colorscheme = { "tokyonight", "habamax" } },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
})
