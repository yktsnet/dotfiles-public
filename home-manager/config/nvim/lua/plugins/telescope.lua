return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          file_ignore_patterns = { ".git/", "node_modules/", "%.lock" },
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case", "--hidden",
          },
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
        },
      })
      local ok, _ = pcall(telescope.load_extension, "fzf")
      if not ok then
        vim.notify("[telescope] fzf-native failed to load. Rebuilding after startup...", vim.log.levels.WARN)
        vim.api.nvim_create_autocmd("User", {
          pattern = "LazyDone",
          callback = function()
            vim.schedule(function()
              require("lazy").build({ plugins = { "telescope-fzf-native.nvim" }, show = false })
            end)
          end,
          once = true,
        })
      end


      local multi_root = { "~/dotfiles", "~/projects", "~/github-public" }

      local function get_project_root()
        local root = vim.fs.root(0, { ".git", "package.json" })
        if not root or root == "" then
          root = vim.fn.expand("%:p:h")
        end
        if root == "" or vim.bo.buftype == "nofile" then
          root = vim.fn.getcwd()
        end
        return root
      end

      vim.keymap.set("n", "<leader>f", function()
        local root = get_project_root()
        builtin.find_files({
          cwd = root,
          prompt_title = "Find Files (" .. vim.fs.basename(root) .. ")",
        })
      end, { desc = "Find files (project root)" })

      vim.keymap.set("n", "<leader>F", function()
        builtin.find_files({ search_dirs = multi_root })
      end, { desc = "Find files (multi-root)" })

      vim.keymap.set("n", "<leader>g", function()
        local root = get_project_root()
        builtin.live_grep({
          cwd = root,
          prompt_title = "Live Grep (" .. vim.fs.basename(root) .. ")",
        })
      end, { desc = "Live grep (project root)" })

      vim.keymap.set("n", "<leader>G", function()
        builtin.live_grep({ search_dirs = multi_root })
      end, { desc = "Live grep (multi-root)" })

      vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
      vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Buffers" })
    end,
  },
}
