return {
  {
    "olivercederborg/poimandres.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("poimandres").setup({})
      vim.cmd("colorscheme poimandres")
    end,
  },
}
