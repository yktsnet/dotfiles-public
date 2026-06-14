local discipline = require("discipline")
discipline.cowboy()

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ============================================================
-- レジスタを汚さない系 (craftzdog)
-- ============================================================

-- x で削除してもヤンクレジスタを上書きしない
keymap("n", "x", '"_x')

-- 最後にヤンクしたもの（レジスタ0）からペースト
keymap("n", "<Leader>p", '"0p')
keymap("n", "<Leader>P", '"0P')
keymap("v", "<Leader>p", '"0p')

-- ブラックホールレジスタへの change（ペーストバッファを保護）
keymap("n", "<Leader>c", '"_c')
keymap("n", "<Leader>C", '"_C')
keymap("v", "<Leader>c", '"_c')
keymap("v", "<Leader>C", '"_C')

-- ブラックホールレジスタへの delete（ペーストバッファを保護）
keymap("n", "<Leader>d", '"_d')
keymap("n", "<Leader>D", '"_D')
keymap("v", "<Leader>d", '"_d')
keymap("v", "<Leader>D", '"_D')

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
-- タブ操作 (craftzdog)
-- ============================================================

keymap("n", "te", ":tabedit")
keymap("n", "<tab>", ":tabnext<Return>", opts)
keymap("n", "<s-tab>", ":tabprev<Return>", opts)

-- ============================================================
-- ウィンドウ分割・移動 (craftzdog)
-- ============================================================

-- 分割
keymap("n", "ss", ":split<Return>", opts)
keymap("n", "sv", ":vsplit<Return>", opts)

-- 移動（Alt+矢印は vim-tmux-navigator に委譲）
keymap("n", "sh", "<C-w>h")
keymap("n", "sk", "<C-w>k")
keymap("n", "sj", "<C-w>j")
keymap("n", "sl", "<C-w>l")

-- リサイズ
keymap("n", "<C-w><left>",  "<C-w><")
keymap("n", "<C-w><right>", "<C-w>>")
keymap("n", "<C-w><up>",    "<C-w>+")
keymap("n", "<C-w><down>",  "<C-w>-")

-- ============================================================
-- Diagnostics (craftzdog)
-- ============================================================

-- 次のエラー・警告へジャンプ
keymap("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- エラー詳細フローティング表示（旧 <leader>d を移動）
keymap("n", "<leader>di", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- ============================================================
-- LSP ユーティリティ (craftzdog)
-- ============================================================

-- Inlay Hints のトグル（LSP 接続時のみ有効）
keymap("n", "<leader>i", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle Inlay Hints" })

-- ============================================================
-- ファイルパス・内容コピー (ykts 独自 / キー移動)
-- ============================================================

-- <leader>cp = 相対パスをクリップボードにコピー（旧 <leader>p）
keymap("n", "<leader>cp", function()
  vim.fn.setreg("+", vim.fn.expand("%:."))
end, { desc = "Copy relative path" })

-- <leader>cP = 絶対パスをクリップボードにコピー（旧 <leader>P）
keymap("n", "<leader>cP", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy absolute path" })

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
