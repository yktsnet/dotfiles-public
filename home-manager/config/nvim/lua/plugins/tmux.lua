return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<M-Left>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window Left" },
      { "<M-Down>", "<cmd>TmuxNavigateDown<cr>", desc = "Window Down" },
      { "<M-Up>", "<cmd>TmuxNavigateUp<cr>", desc = "Window Up" },
      { "<M-Right>", "<cmd>TmuxNavigateRight<cr>", desc = "Window Right" },
      { "<M-/>", "<cmd>vsplit<cr>", desc = "Split Window Vertically" },
      { "<M-->", "<cmd>split<cr>", desc = "Split Window Horizontally" },
      { "<M-x>", "<cmd>close<cr>", desc = "Close Split Window" },
    },
  },
}
