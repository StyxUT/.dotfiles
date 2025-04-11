require('telescope').setup({
  defaults = {
    mappings = {
      i = {
        ["<C-u>"] = false,
        ["<C-d>"] = false,
      },
    },
  },
})

-- Optional: Load extensions
-- require('telescope').load_extension('fzf')

