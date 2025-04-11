local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "gopls" },
})

return require("packer").startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'ellisonleao/gruvbox.nvim'
  use 'craftzdog/solarized-osaka.nvim'
  use 'nvim-tree/nvim-tree.lua'
  use 'nvim-tree/nvim-web-devicons'
  use 'nvim-lualine/lualine.nvim'
  use 'neovim/nvim-lspconfig'
  use 'mfussenegger/nvim-dap' -- Core DAP plugin
  use 'rcarriga/nvim-dap-ui'  -- UI for DAP
  use 'leoluz/nvim-dap-go'    -- Go-specific DAP integration
  --use 'theHamsta/nvim-dap-virtual-text'
	use 'nvim-neotest/nvim-nio'
  use { 'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim' }
  use 'nvim-treesitter/nvim-treesitter'
  use {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.0',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use {
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-nvim-lsp",  -- LSP source for nvim-cmp
      "hrsh7th/cmp-buffer",     -- Buffer words completion
      "hrsh7th/cmp-path",       -- File path completion
      "L3MON4D3/LuaSnip",       -- Snippet engine
      "saadparwaiz1/cmp_luasnip" -- Snippet completions
    }
  }
  use {
  	"nvim-neotest/neotest",
  	requires = {
    	"nvim-lua/plenary.nvim",
    	"nvim-treesitter/nvim-treesitter",
    	"nvim-neotest/neotest-go"
  }
}

  if packer_bootstrap then
    require("packer").sync()
  end
end)
