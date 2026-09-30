-- Options are automatically loaded before lazy.nvim startup.
-- Default options that are always set:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
-- VSCode-like editing feel. Mouse ("a") is already LazyVim's default and is
-- deliberately left stock.
local opt = vim.opt

opt.scrolloff = 8 -- cursor never hugs the window edge
opt.wrap = true -- wrap long lines
opt.number = true
opt.relativenumber = true -- hybrid line numbers
opt.numberwidth = 4 -- steady gutter width
opt.cursorline = true
opt.signcolumn = "yes" -- no gutter jump when diagnostics appear
