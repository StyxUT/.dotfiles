local ok, snacks = pcall(require, "snacks")
if not ok then return end
snacks.setup({
  input = {},
  picker = {},
  terminal = {},   -- used by opencode.nvim provider
})

