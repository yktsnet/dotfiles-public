return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- エディタのメイン背景色(Normalグループのbg)を動的に取得する
      local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
      local normal_bg = normal_hl and normal_hl.bg
      local bg_color = "NONE"
      if normal_bg then
        bg_color = string.format("#%06x", normal_bg)
      end

      -- ステータスライン自体の裏地背景をエディタ背景と同色にする（これで完全に同化する）
      vim.api.nvim_set_hl(0, "StatusLine", { bg = bg_color })
      vim.api.nvim_set_hl(0, "StatusLineNC", { bg = bg_color })

      -- Poimandresのlualineテーマを取得し、背景をエディタ背景と同色にして同化させる
      local poimandres = require("lualine.themes.poimandres")
      for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
        if poimandres[mode] then
          if poimandres[mode].b then
            poimandres[mode].b.bg = bg_color
          else
            poimandres[mode].b = { bg = bg_color }
          end
          if poimandres[mode].c then
            poimandres[mode].c.bg = bg_color
          else
            poimandres[mode].c = { bg = bg_color }
          end
        end
      end

      require("lualine").setup({
        options = {
          theme = poimandres, -- カスタマイズしたテーマを適用
          section_separators = { left = "", right = "" }, -- 矢印を廃止してすっきりしたフラットデザインにする
          component_separators = { left = "|", right = "|" }, -- 内側の区切りはシンプルな縦棒にする
          globalstatus = true, -- ウィンドウ分割時もステータスラインを最下部に1本化してすっきりさせる
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" }, -- Gitブランチと追加・変更・削除行数
          lualine_c = {
            {
              "filename",
              file_status = true,
              path = 1, -- ファイルの相対パスを表示して場所をわかりやすくする
            },
            {
              "diagnostics", -- エラー/警告数（LSP）を左側に配置
              sources = { "nvim_diagnostic" },
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
            },
            {
              "aerial", -- 現在カーソルがある関数名・クラス名を表示
              sep = " > ",
            },
          },
          lualine_x = {}, -- 右側は完全に非表示にしてミニマルにする
          lualine_y = {},
          lualine_z = {},
        },
      })
    end,
  },
}
