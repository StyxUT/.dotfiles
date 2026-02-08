require('telescope').setup({
  defaults = {
	  file_ignore_patterns = {},
    mappings = {
      i = {
        ["<C-u>"] = false,
        ["<C-d>"] = false,
      },
    },
		pickers = {
			find_files = {
			  no_ignore = true,
				hidden = true,
  },
})

-- Optional: Load extensions
-- require('telescope').load_extension('fzf')

