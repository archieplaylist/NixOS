-- Keymaps are automatically loaded on the VeryLazy event.
-- Default keymaps that are always set:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- VSCode muscle memory for the keys LazyVim doesn't already own. <C-h/j/k/l>
-- come from LazyVim (normal + terminal), <C-/> hides the terminal there, and
-- <C-p>/<C-S-p> are untouched in normal mode. Bodies are wrapped in functions:
-- keymaps.lua runs on VeryLazy, so the Snacks global is only bound by then.
local map = vim.keymap.set

map("n", "<C-p>", function() Snacks.picker.pick("files") end, { desc = "Quick Open" })
map("n", "<C-S-p>", function() Snacks.picker.pick("pickers") end, { desc = "Command Palette" })
-- bufferline's cycle, same order as the tab bar you are looking at
map("n", "<C-S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous Tab" })
map("n", "<C-S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Tab" })
