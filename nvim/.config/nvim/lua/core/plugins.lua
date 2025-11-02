local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end
local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
  use("wbthomason/packer.nvim")

  -- your existing plugins…
  use("ellisonleao/gruvbox.nvim")
  use("craftzdog/solarized-osaka.nvim")
  use("nvim-tree/nvim-tree.lua")
  use("nvim-tree/nvim-web-devicons")
  use("nvim-lualine/lualine.nvim")
  use("neovim/nvim-lspconfig")
  use("mfussenegger/nvim-dap")
  use("rcarriga/nvim-dap-ui")
  use("leoluz/nvim-dap-go")
  use("nvim-neotest/nvim-nio")

  use({ "williamboman/mason.nvim", requires = { "williamboman/mason-lspconfig.nvim" } })

  use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
  use({ "nvim-telescope/telescope.nvim", requires = { "nvim-lua/plenary.nvim" } })
  use({
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-nvim-lsp","hrsh7th/cmp-buffer","hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip","saadparwaiz1/cmp_luasnip",
    },
  })

  use({
    "nvim-neotest/neotest",
    requires = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter", "nvim-neotest/neotest-go" },
  })

  -- NEW: snacks + opencode
  use("folke/snacks.nvim")
  use({ "NickvanDyke/opencode.nvim", requires = { "folke/snacks.nvim" } })

  if packer_bootstrap then require("packer").sync() end
end)

