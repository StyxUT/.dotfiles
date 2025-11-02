vim.o.autoread = true
vim.g.opencode_opts = {
  provider = { enabled = "snacks" },
  auto_reload = true,
}

local ok, oc = pcall(require, "opencode")
if not ok then return end

vim.keymap.set({ "n", "x" }, "<C-a>", function() oc.ask("@this: ", { submit = true }) end, { desc = "OpenCode ask" })
vim.keymap.set({ "n", "x" }, "<C-x>", function() oc.select() end, { desc = "OpenCode select" })
vim.keymap.set({ "n", "x" }, "ga",     function() oc.prompt("@this") end, { desc = "OpenCode add context" })
vim.keymap.set({ "n", "t" }, "<C-.>",  function() oc.toggle() end, { desc = "OpenCode toggle TUI" })
vim.keymap.set("n", "<S-C-u>", function() oc.command("session.half.page.up") end)
vim.keymap.set("n", "<S-C-d>", function() oc.command("session.half.page.down") end)

