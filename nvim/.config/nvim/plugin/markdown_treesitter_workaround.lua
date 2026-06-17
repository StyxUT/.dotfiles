local original_start = vim.treesitter.start

vim.treesitter.start = function(bufnr, lang)
  local buffer = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.bo[buffer].filetype
  local language = lang or filetype

  if filetype == "markdown" or language == "markdown" or language == "markdown_inline" then
    return
  end

  return original_start(buffer, lang)
end

local group = vim.api.nvim_create_augroup("MarkdownTreesitterWorkaround", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "markdown" },
  callback = function(args)
    pcall(vim.treesitter.stop, args.buf)
    vim.b[args.buf].ts_highlight = false
  end,
})
