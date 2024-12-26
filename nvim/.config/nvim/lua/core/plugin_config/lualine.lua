require("lualine").setup {
	options = {
		icons_enabled = true,
		theme = 'solarized-osaka',
	},
	sections = {
		lualine_a = {
			{
				'filename',
				path = 1,
			}
		}
	}
}
