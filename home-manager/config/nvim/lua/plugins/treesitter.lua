return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "python", "javascript", "typescript",
        "go", "php", "nix", "markdown", "toml", "yaml", "bash",
      },
      highlight = { enable = true },
    },
  },
}
