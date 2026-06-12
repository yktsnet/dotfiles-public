vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("options")
require("keymaps")

-- ロックファイルの書き込み権限をチェックし、読み取り専用環境の場合は書き込み可能領域に逃がす
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
local f = io.open(lockfile, "a")
if f then
  f:close()
else
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json"
end

require("lazy").setup({
  { import = "plugins.colorscheme" },
  { import = "plugins.telescope" },
  { import = "plugins.yazi" },
  { import = "plugins.treesitter" },
  { import = "plugins.lsp" },
  { import = "plugins.format" },
  { import = "plugins.lualine" },
  { import = "plugins.lazygit" },
  { import = "plugins.gitsigns" },
}, {
  lockfile = lockfile,
})
