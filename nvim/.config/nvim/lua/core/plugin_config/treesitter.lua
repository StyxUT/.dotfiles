local ok, cfg = pcall(require, "nvim-treesitter.configs")
if not ok then return end

cfg.setup({
  ensure_installed = { "json", "lua", "sql", "yaml", "vim", "go" },
  ignore_install = { "markdown", "markdown_inline" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
    -- Neovim 0.12.x can crash on markdown fenced code blocks via Treesitter conceal_lines.
    disable = { "markdown", "markdown_inline" },
  },
  indent = {
    enable = true,
    disable = { "markdown", "markdown_inline" },
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
})
