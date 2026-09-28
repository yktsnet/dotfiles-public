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

      -- oil の recursive_delete は 1ディレクトリあたり 10000 エントリのバッファを確保しつつ
      -- 子を無制限に並行再帰するため、大きなツリーで luv の dirents 解放が壊れ nvim ごと abort する。
      -- 削除だけ外部コマンドに委ねて回避する。
      local fs = require("oil.fs")
      fs.recursive_delete = function(entry_type, path, cb)
        if entry_type ~= "directory" then
          return vim.uv.fs_unlink(path, cb)
        end
        vim.system({ "rm", "-rf", "--", path }, { text = true }, function(res)
          vim.schedule(function()
            if res.code == 0 then
              cb()
            else
              cb("rm -rf failed: " .. (res.stderr or ""))
            end
          end)
        end)
      end

      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
      vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Oil (current file dir)" })
      vim.keymap.set("n", "<leader>E", function()
        require("oil").open(vim.fn.getcwd())
      end, { desc = "Oil (cwd)" })
    end,
  },
}
