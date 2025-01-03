vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Copy/paste from system clipboard
vim.keymap.set({ 'n', 'x' }, 'cp', '"+y')
vim.keymap.set({ 'n', 'x' }, 'cv', '"+p')
-- Delete without changing the registers
vim.keymap.set({ 'n', 'x' }, 'x', '"_x')

vim.opt.backspace = '2'
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.cursorline = true  
vim.opt.autoread = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.relativenumber = true
-- vim.opt.shiftroud = true
-- vim.opt.expandtab = true

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')
--vim.keymap.set('n', 'y', '"+y')
--vim.keymap.set('n', '<silent>p', ':r !wl-paste<CR><CR>')
