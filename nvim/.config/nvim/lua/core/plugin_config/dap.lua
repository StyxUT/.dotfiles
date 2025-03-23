require("dap-go").setup()
--require("nvim-dap-virtual-text").setup()

local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

-- Automatically open/close dap-ui when debugging starts/stops
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Keybindings for DAP
vim.keymap.set("n", "<F5>", ":lua require'dap'.continue()<CR>", { silent = true })
vim.keymap.set("n", "<F10>", ":lua require'dap'.step_over()<CR>", { silent = true })
vim.keymap.set("n", "<F11>", ":lua require'dap'.step_into()<CR>", { silent = true })
vim.keymap.set("n", "<F12>", ":lua require'dap'.step_out()<CR>", { silent = true })
vim.keymap.set("n", "<Leader>b", ":lua require'dap'.toggle_breakpoint()<CR>", { silent = true })
vim.keymap.set("n", "<Leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", { silent = true })
vim.keymap.set("n", "<Leader>dr", ":lua require'dap'.repl.open()<CR>", { silent = true })
vim.keymap.set("n", "<Leader>dl", ":lua require'dap'.run_last()<CR>", { silent = true })

