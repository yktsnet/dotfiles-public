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
vim.opt.wrap = true -- Wrap lines
vim.opt.scrolloff = 10
vim.opt.conceallevel = 2 -- render-markdown などのインライン装飾・マークダウンレンダリング用

-- Undercurl support
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- インクリメンタル置換プレビューを別スプリットで表示
vim.opt.inccommand = "split"

-- ウィンドウ分割時にカーソル行を固定
vim.opt.splitkeep = "cursor"

-- /tmp のバックアップ無効
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }

-- ブロックコメント中の * 自動挿入
vim.opt.formatoptions:append({ "r" })

-- コマンド未入力時にコマンドラインを非表示
vim.opt.cmdheight = 0

local augroup = vim.api.nvim_create_augroup("CustomAutoCmds", { clear = true })

-- Save last visited directory to a file on exit for shell auto-cd
local last_valid_dir = vim.fn.getcwd()
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup,
  callback = function()
    local dir = vim.fn.expand("%:p:h")
    if vim.fn.isdirectory(dir) == 1 then
      last_valid_dir = dir
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = augroup,
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

-- Force zsh filetype for scripts under zsh/functions/ to enable Aerial and Treesitter
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup,
  pattern = "*/zsh/functions/*.sh",
  callback = function()
    vim.bo.filetype = "zsh"
  end,
})


-- 再起動時に最後にカーソルがあった位置に戻る
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})



