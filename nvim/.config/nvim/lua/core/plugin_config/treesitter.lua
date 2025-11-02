local ok, cfg = pcall(require, "nvim-treesitter.configs")
if not ok then return end

cfg.setup({
  ensure_installed = { "json", "lua", "sql", "yaml", "vim", "go" },
  highlight = { enable = true, additional_vim_regex_highlighting = false },
  indent = { enable = true },
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

