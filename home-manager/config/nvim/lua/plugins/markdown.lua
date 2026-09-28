return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      file_types = { "markdown" },
      heading = {
        position = "inline",
        icons = { "# ", "# ", "# ", "# ", "# ", "# " },
        left_pad = 0,
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      -- RenderMarkdownCode(Inline) はデフォルトで ColorColumn にリンクされ fg 未指定のため
      -- テーマによっては文字色と背景色が近くなり視認性が低い。poimandres の配色で明示指定する。
      local group = vim.api.nvim_create_augroup("RenderMarkdownContrast", { clear = true })
      local function apply()
        -- Code block contrast adjustment for Poimandres
        vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#252b3b", fg = "#E4F0FB" })
        vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = "#252b3b", fg = "#5DE4C7" })

        -- Poimandres カラーパレットに基づいた H1 〜 H6 の見出しデザイン
        -- H1: Teal (#5DE4C7) - 最重要見出し（メインアクセント）
        vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#5DE4C7", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#1b3333", fg = "#5DE4C7", bold = true })

        -- H2: Sky Blue (#89DDFF) - セクション見出し
        vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#89DDFF", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#1e2e3d", fg = "#89DDFF", bold = true })

        -- H3: Bright Yellow (#FFFAC2) - サブセクション（視認性の高いウォームカラー）
        vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#FFFAC2", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#332e1e", fg = "#FFFAC2", bold = true })

        -- H4: Soft Pink (#FCC5E9) - 小見出し
        vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#FCC5E9", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#332332", fg = "#FCC5E9", bold = true })

        -- H5: Ice Light Blue (#ADD7FF) - 詳細項目
        vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#ADD7FF", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#212836", fg = "#ADD7FF", bold = true })

        -- H6: Muted Slate (#767C9D) - 補足
        vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#767C9D", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#212330", fg = "#767C9D", bold = true })
      end
      apply()
      vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = apply })
    end,
    keys = {
      { "<leader>M", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Render Markdown" },
    },
  },
  -- markdown-preview.nvim (Mermaid 等のブラウザプレビュー用) は
  -- home-manager/modules/nvim.nix が別ファイルとして配置する（nixpkgs 版を使い、
  -- 実行時の GitHub ダウンロードに依存させないため）
}
