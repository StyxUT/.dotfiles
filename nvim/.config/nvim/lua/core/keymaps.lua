vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Development
vim.keymap.set('n', '<leader>r', function()
  vim.cmd('!go run .')
end, { desc = "Run current Go file" })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>u', function()
	vim.cmd('!go mod tidy && go build')
end, {desc = "Tidy and build Go package" })
--vim.keymap.set('n', '<leader>t', function()
--	vim.cmd('!go test -v')
--end, {desc = "Run all tests" })
vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = "Signature help" })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "LSP Hover Docs" })
vim.keymap.set("n", "<leader>km", "<cmd>Telescope keymaps<CR>", { desc = "List keymaps" })
vim.keymap.set("n", "<leader>dt", function()
  require("dap-go").debug_test()
end, { desc = "Debug Go test" })
vim.keymap.set('n', '<leader>dq', function()
  require('dap').terminate()
end, { desc = "Stop (terminate) DAP session" })

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
vim.opt.number = true
-- vim.opt.shiftroud = true
-- vim.opt.expandtab = true

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')
--vim.keymap.set('n', 'y', '"+y')
--vim.keymap.set('n', '<silent>p', ':r !wl-paste<CR><CR>')
