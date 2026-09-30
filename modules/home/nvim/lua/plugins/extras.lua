-- Extras transcribed from the LazyVim web configurator's lazyvim.json, which
-- is inert on its own: nothing loads unless the extra is imported here.
--
-- `lazyvim.plugins.extras.vscode` is deliberately NOT imported: it returns {}
-- unless nvim runs as the vscode-nvim extension backend (vim.g.vscode). It
-- configures "let VSCode drive nvim", not a VSCode-like editing feel.
return {
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.lang.ansible" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.tailwind" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
}
