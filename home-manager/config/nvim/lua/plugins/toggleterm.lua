return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      direction = "float",
      dir = function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname ~= "" and vim.bo.buftype == "" then
          return vim.fn.expand("%:p:h")
        end
        return vim.fn.getcwd()
      end,
      float_opts = {
        winblend = 25, -- 75%の不透明度 (25%の透明度)
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      local Terminal = require("toggleterm.terminal").Terminal
      local my_term = nil
      local last_dir = nil

      -- Normalモードでのみ \ で開閉する（フォルダが切り替わったら自動で立ち上げ直す）
      vim.keymap.set("n", "\\", function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local dir = vim.fn.getcwd()
        if bufname ~= "" and vim.bo.buftype == "" then
          dir = vim.fn.expand("%:p:h")
        end

        -- ディレクトリが変わっていたら、既存のターミナルを破棄して作り直す
        if my_term and last_dir ~= dir then
          my_term:shutdown()
          my_term = nil
        end

        if not my_term then
          my_term = Terminal:new({
            direction = "float",
            dir = dir,
            on_close = function()
              my_term = nil
              last_dir = nil
            end,
          })
          last_dir = dir
        end

        my_term:toggle()
      end, { desc = "Toggle Terminal" })

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
