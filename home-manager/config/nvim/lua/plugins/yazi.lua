return {
  {
    "mikavilpas/yazi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>e",
        function() require("yazi").yazi(nil, vim.fn.expand("%:p:h")) end,
        desc = "Yazi (current file dir)",
      },
      {
        "<leader>E",
        function() require("yazi").yazi(nil, vim.fn.getcwd()) end,
        desc = "Yazi (cwd)",
      },
    },
    opts = {
      open_for_directories = true,
      floating_window_scaling_factor = 0.9,
    },
  },
}
