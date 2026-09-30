-- ts-comments is already loaded but only detects the comment string; it has
-- no toggle. mini.comment is one dependency-free file and gets block comments,
-- local commentstring inference and dot-repeat right, which a hand-rolled
-- toggler wouldn't. It maps itself in setup(), so no `keys` here.
return {
  {
    "nvim-mini/mini.comment",
    version = "*",
    main = "mini.comment",
    config = function()
      require("mini.comment").setup({
        mappings = {
          comment = "<C-/>",
          comment_line = "<C-/>",
          comment_visual = "<C-/>",
        },
      })
    end,
  },
}
