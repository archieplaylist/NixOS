-- ts-comments is already loaded but only detects the comment string; it has
-- no toggle. mini.comment is one dependency-free file and gets block
-- comments + visual mode right, which a hand-rolled toggler wouldn't.
return {
  {
    "echasnovski/mini.comment",
    version = "*",
    main = "mini.comment",
    config = function()
      require("mini.comment").setup()
    end,
    keys = {
      {
        "<C-/>",
        function() require("mini.comment").toggle_linewise() end,
        mode = { "n", "x" },
        desc = "Toggle Comment",
      },
    },
  },
}
