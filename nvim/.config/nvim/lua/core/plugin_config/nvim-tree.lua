vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
  filters = {
		git_ignored = false
	},
})

vim.keymap.set('n', '<c-n>', ':NvimTreeFindFileToggle<CR>')
