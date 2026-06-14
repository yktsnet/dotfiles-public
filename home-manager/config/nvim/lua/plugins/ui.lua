return {
  -- コマンドライン・通知・ポップアップの UI 刷新
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = function()
      local focused = true

      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function() focused = true end,
      })
      vim.api.nvim_create_autocmd("FocusLost", {
        callback = function() focused = false end,
      })

      return {
        routes = {
          -- フォーカスを失った時はシステム通知として送る
          {
            filter = { cond = function() return not focused end },
            view = "notify_send",
            opts = { stop = false },
          },
          -- "No information available" の無駄な通知を抑制
          {
            filter = { event = "notify", find = "No information available" },
            opts = { skip = true },
          },
        },
        commands = {
          all = {
            view = "split",
            opts = { enter = true, format = "details" },
            filter = {},
          },
        },
        presets = {
          lsp_doc_border = true,   -- LSP ホバーにボーダー表示
          bottom_search = false,
          command_palette = false,
          long_message_to_split = true,
        },
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
      }
    end,
  },

  -- 通知ポップアップ
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 5000,
    },
  },

  -- 分割ウィンドウ時のファイル名フローティング表示
  {
    "b0o/incline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "BufReadPre",
    priority = 1200,
    config = function()
      require("incline").setup({
        window = { margin = { vertical = 0, horizontal = 1 } },
        hide = { cursorline = true },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if vim.bo[props.buf].modified then
            filename = "[+] " .. filename
          end
          local icon, color = require("nvim-web-devicons").get_icon_color(filename)
          return { { icon, guifg = color }, { " " }, { filename } }
        end,
      })
    end,
  },

  -- 集中モード（サイドバー・lualine を隠してコードだけを表示）
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      plugins = {
        gitsigns = true,
        tmux = true,
      },
    },
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
  },
}
