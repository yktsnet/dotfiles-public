return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      keymaps = {
        ["q"] = "actions.close",
        ["cr"] = {
          callback = function()
            local entry = require("oil").get_cursor_entry()
            if entry then
              local dir = require("oil").get_current_dir()
              if dir then
                local path = dir .. entry.name
                local rel = vim.fn.fnamemodify(path, ":.")
                vim.fn.setreg("+", rel)
                vim.notify("Copied relative path: " .. rel)
              end
            end
          end,
          desc = "Copy relative path",
        },
        ["cp"] = {
          callback = function()
            local entry = require("oil").get_cursor_entry()
            if entry then
              local dir = require("oil").get_current_dir()
              if dir then
                local path = dir .. entry.name
                local abs = vim.fn.fnamemodify(path, ":p")
                vim.fn.setreg("+", abs)
                vim.notify("Copied absolute path: " .. abs)
              end
            end
          end,
          desc = "Copy absolute path",
        },
      },
      view_options = {
        show_hidden = true,
      },
    },
    config = function(_, opts)
      require("oil").setup(opts)
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
      vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Oil (current file dir)" })
      vim.keymap.set("n", "<leader>E", function()
        require("oil").open(vim.fn.getcwd())
      end, { desc = "Oil (cwd)" })
    end,
  },
}
