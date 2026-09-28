return {
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<M-j>", function()
        if vim.fn.winnr() == vim.fn.winnr("$") then
          vim.fn.system("tmux select-pane -t :.+")
        else
          vim.cmd("wincmd w")
        end
      end, desc = "Next Window or Tmux Pane" },
      { "<M-k>", function()
        if vim.fn.winnr() == 1 then
          vim.fn.system("tmux select-pane -t :.-")
        else
          vim.cmd("wincmd W")
        end
      end, desc = "Previous Window or Tmux Pane" },
    },
  },
}
