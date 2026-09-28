local keymap = vim.keymap.set
local opts = { silent = true }

-- ============================================================
-- レジスタを汚さない系 (craftzdog)
-- ============================================================

-- x で削除してもヤンクレジスタを上書きしない
keymap("n", "x", '"_x')

-- 最後にヤンクしたもの（レジスタ0）からペースト
keymap("n", "<Leader>p", '"0p')
keymap("n", "<Leader>P", '"0P')
keymap("v", "<Leader>p", '"0p')


-- ============================================================
-- 数値・インクリメント (craftzdog)
-- ============================================================

keymap("n", "+", "<C-a>")
-- "-" は oil.nvim（親ディレクトリを開く）で使用中のためスキップ

-- ============================================================
-- テキスト操作 (craftzdog)
-- ============================================================

-- 単語を後方から選択して削除（ヤンクレジスタを汚さない）
keymap("n", "dw", 'vb"_d')


-- 改行追加時にインデントゴミを残さない
keymap("n", "<Leader>o", "o<Esc>^Da", opts)
keymap("n", "<Leader>O", "O<Esc>^Da", opts)

-- ============================================================
-- カーソル移動
-- ============================================================

-- 表示行での移動（折り返し行でも自然に移動）。ただし、10j のようにカウントを指定した場合は論理行移動を維持
keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- ============================================================

-- タブ操作 (craftzdog)
-- ============================================================

keymap("n", "te", ":tabedit")
keymap("n", "<tab>", ":tabnext<Return>", opts)
keymap("n", "<s-tab>", ":tabprev<Return>", opts)

-- ============================================================
-- ウィンドウ分割・移動 (craftzdog)
-- ============================================================

-- 移動（Alt+矢印は vim-tmux-navigator に委譲）
keymap("n", "sh", "<C-w>h")
keymap("n", "sk", "<C-w>k")
keymap("n", "sj", "<C-w>j")
keymap("n", "sl", "<C-w>l")

-- 分割・クローズ（Nvim 内側の層。tmux 側は Alt キー）
keymap("n", "sv", "<cmd>vsplit<cr>", opts)
keymap("n", "ss", "<cmd>split<cr>", opts)
keymap("n", "sx", "<cmd>close<cr>", opts)

-- リサイズ
keymap("n", "<C-w><left>",  "<C-w><")
keymap("n", "<C-w><right>", "<C-w>>")
keymap("n", "<C-w><up>",    "<C-w>+")
keymap("n", "<C-w><down>",  "<C-w>-")

-- ============================================================
-- Diagnostics (craftzdog)
-- ============================================================

-- 次・前のエラー・警告へジャンプ
keymap("n", "<C-j>", function()
  vim.diagnostic.jump({ count = 1 })
end, opts)

keymap("n", "<C-k>", function()
  vim.diagnostic.jump({ count = -1 })
end, opts)

-- エラー詳細フローティング表示（旧 <leader>d を移動）
keymap("n", "<leader>di", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- ============================================================
-- LSP ユーティリティ (craftzdog)
-- ============================================================

-- Inlay Hints のトグル（LSP 接続時のみ有効）
keymap("n", "<leader>i", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
end, { desc = "Toggle Inlay Hints" })


-- <leader>cp = 絶対パスをクリップボードにコピー
keymap("n", "<leader>cp", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.setreg("+", filepath)
  vim.notify("Copied absolute path: " .. filepath)
end, { desc = "Copy absolute path" })

-- <leader>cr = 相対パスをクリップボードにコピー
keymap("n", "<leader>cr", function()
  local filepath = vim.fn.expand("%:.")
  vim.fn.setreg("+", filepath)
  vim.notify("Copied relative path: " .. filepath)
end, { desc = "Copy relative path" })

-- <leader>y = ファイル内容をヘッダ付きでコピー（変更なし）
keymap("n", "<leader>y", function()
  local filepath = vim.fn.expand("%:~")
  local header = "--- " .. filepath .. " ---\n"
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = header .. table.concat(lines, "\n")
  vim.fn.setreg("+", content)
  vim.notify("Copied: " .. filepath)
end, { desc = "Copy file with path header" })

-- ============================================================
-- ファイル種別実行 (ykts 独自)
-- ============================================================

keymap("n", "<leader>x", function()
  local ext = vim.fn.expand("%:e")
  local file = vim.fn.expand("%:p")
  if ext == "py" then
    vim.cmd("!" .. "python3 " .. file)
  elseif ext == "sh" then
    vim.cmd("!" .. "bash " .. file)
  else
    vim.notify("No executor for extension: " .. ext, vim.log.levels.WARN)
  end
end, { desc = "Execute file by type" })
