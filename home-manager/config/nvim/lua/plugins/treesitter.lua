return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "python", "javascript", "typescript",
        "go", "php", "nix", "markdown", "markdown_inline", "toml", "yaml", "bash", "zsh",
        "regex", -- noice.nvim のコマンドライン強調に使用
      },
      highlight = { enable = true },
    },
  },
}
