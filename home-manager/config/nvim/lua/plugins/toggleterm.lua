return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      direction = "float",
      dir = function()
        return vim.fn.getcwd()
      end,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Normalモードでのみ \ で開閉する（ターミナル内での \ 入力を妨げないため）
      vim.keymap.set("n", "\\", "<CMD>ToggleTerm<CR>", { desc = "Toggle Terminal" })

      -- Normal / Visual mode keymaps to send text
      vim.keymap.set("x", "<leader>ts", "<CMD>ToggleTermSendVisualSelection<CR>", { desc = "Send visual selection to terminal" })
      vim.keymap.set("n", "<leader>tl", "<CMD>ToggleTermSendCurrentLine<CR>", { desc = "Send current line to terminal" })

      -- Terminal-mode specific keymaps
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*",
        callback = function()
          local opts_term = { buffer = 0 }
          vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], opts_term)
          vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts_term)
          vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts_term)
          vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts_term)
          vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts_term)
        end,
      })
    end,
  },
}
