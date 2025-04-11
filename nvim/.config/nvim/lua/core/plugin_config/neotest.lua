local neotest = require("neotest")

neotest.setup({
  adapters = {
    require("neotest-go")({
      args = { "-coverprofile=coverage.out" }
    })
  }
})

vim.keymap.set("n", "<leader>tn", function() neotest.run.run() end, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "Run all tests in file" })
vim.keymap.set("n", "<leader>tl", function() neotest.run.run_last() end, { desc = "Re-run last test" })
vim.keymap.set("n", "<leader>to", function() neotest.output.open() end, { desc = "Open test output" })
vim.keymap.set("n", "<leader>ts", function() neotest.summary.toggle() end, { desc = "Toggle test summary" })
vim.keymap.set("n", "<leader>tp", function()
  require("neotest").run.run(".")
end, { desc = "Run all tests in current package" })


