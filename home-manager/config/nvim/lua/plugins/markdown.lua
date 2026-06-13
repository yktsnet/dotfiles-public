return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      heading = {
        backgrounds = {}, -- 見出しの背景のベタ塗りを無効化
      },
      code = {
        highlight = "RenderMarkdownCode",
        highlight_inline = "RenderMarkdownCodeInline",
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      -- Poimandres テーマのカラーパレットを適用
      local colors = {
        bg_dark = "#212437", -- コードブロックの背景用（やや明るいネイビーグレー）
        inline_bg = "#252837", -- インラインコードの背景用（Poimandresの選択範囲色に近い）
        blue = "#89ddff", -- インラインコードの文字色、H2 / H5
        teal = "#5de4c7", -- H1 / H4
        pink = "#f07178", -- H3 / H6
      }

      -- インラインコードとコードブロックのハイライト設定（文字が潰れないようにコントラストを確保）
      vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = colors.bg_dark })
      vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = colors.inline_bg, fg = colors.blue })

      -- 見出しの文字色を Poimandres のアクセントカラーに設定して美しくする
      vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = colors.teal, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = colors.blue, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = colors.pink, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = colors.teal, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = colors.blue, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = colors.pink, bold = true })
    end,
  },
}
