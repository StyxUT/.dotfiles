-- Neovim 0.11+ style LSP setup (with fallback for older Nvim)

-- capabilities (optional, works with nvim-cmp if present)
local capabilities = vim.lsp.protocol.make_client_capabilities()
pcall(function()
  capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
end)

-- your on_attach (optional)
local on_attach = function(_, bufnr)
  local map = function(m, lhs, rhs) vim.keymap.set(m, lhs, rhs, { buffer = bufnr }) end
  map("n", "K", vim.lsp.buf.hover)
  map("n", "gd", vim.lsp.buf.definition)
  map("n", "gr", vim.lsp.buf.references)
  map("n", "<leader>rn", vim.lsp.buf.rename)
end

-- If you use mason, keep it as-is
pcall(function()
  require("mason").setup()
  require("mason-lspconfig").setup({ ensure_installed = { "gopls" } })
end)

if vim.fn.has("nvim-0.11") == 1 then
  ---------------------------------------------------------------------------
  -- NEW API (preferred on 0.11+)
  ---------------------------------------------------------------------------
  vim.lsp.config("gopls", {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
      gopls = {
        analyses = { unusedparams = true },
        staticcheck = true,
      },
    },
  })
  -- Enable: starts automatically when a matching file/root is opened
  vim.lsp.enable("gopls")
else
  ---------------------------------------------------------------------------
  -- Fallback for older Nvim
  ---------------------------------------------------------------------------
  local ok, lspconfig = pcall(require, "lspconfig")
  if ok then
    lspconfig.gopls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        gopls = {
          analyses = { unusedparams = true },
          staticcheck = true,
        },
      },
    })
  end
end

-- Recommended diagnostics UI defaults (0.11 changed some defaults)
vim.diagnostic.config({ virtual_text = true, severity_sort = true })

