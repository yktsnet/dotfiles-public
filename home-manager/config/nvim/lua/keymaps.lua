local map = vim.keymap.set
-- パスコピー（Rangerの p / P に対応）
map("n", "<leader>p", function()
  vim.fn.setreg("+", vim.fn.expand("%:."))
end, { desc = "Copy relative path" })
map("n", "<leader>P", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy absolute path" })
-- ファイル内容をヘッダ付きでコピー（Rangerの ac に対応）
map("n", "<leader>y", function()
  local filepath = vim.fn.expand("%:~")
  local header = "--- " .. filepath .. " ---\n"
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = header .. table.concat(lines, "\n")
  vim.fn.setreg("+", content)
  vim.notify("Copied: " .. filepath)
end, { desc = "Copy file with path header" })
-- ファイル種別で実行（Rangerの x に対応）
map("n", "<leader>x", function()
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
