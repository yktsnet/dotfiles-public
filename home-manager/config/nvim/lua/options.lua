vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = true
vim.opt.scrolloff = 8

-- Save last visited directory to a file on exit for shell auto-cd
local last_valid_dir = vim.fn.getcwd()
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local dir = vim.fn.expand("%:p:h")
    if vim.fn.isdirectory(dir) == 1 then
      last_valid_dir = dir
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    local cwd_file = os.getenv("NVIM_CWD_FILE")
    if cwd_file and cwd_file ~= "" then
      local f = io.open(cwd_file, "w")
      if f then
        f:write(last_valid_dir)
        f:close()
      end
    end
  end,
})

-- Force zsh filetype for scripts under zsh/neo/ to enable Aerial and Treesitter
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*/zsh/neo/*.sh",
  callback = function()
    vim.bo.filetype = "zsh"
  end,
})

-- 最後に開いていたファイルを自動的に開く（引数なしで起動した場合のみ）
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      for _, file in ipairs(vim.v.oldfiles) do
        if vim.fn.filereadable(file) == 1 then
          local lower_file = file:lower()
          -- 除外したい一時ファイルや特殊ファイルをフィルタリング
          if not lower_file:match("commit_editmsg") and
             not lower_file:match("git%-rebase%-todo") and
             not lower_file:match("/tmp/") and
             not lower_file:match("/private/tmp/") and
             not lower_file:match("%.git/") then
            vim.cmd("edit " .. vim.fn.fnameescape(file))
            break
          end
        end
      end
    end
  end,
})

-- 再起動時に最後にカーソルがあった位置に戻る
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})


