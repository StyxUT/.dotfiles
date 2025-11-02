local function safe(mod) pcall(require, mod) end

safe("core.plugin_config.snacks")         -- snacks first (provider)
safe("core.plugin_config.ai")             -- opencode.nvim
safe("core.plugin_config.treesitter")
safe("core.plugin_config.neotest")
safe("core.plugin_config.lsp")            -- includes mason setup
safe("core.plugin_config.telescope")
safe("core.plugin_config.dap")
safe("core.plugin_config.nvim-tree")
safe("core.plugin_config.lualine")
safe("core.plugin_config.cmp")
safe("core.plugin_config.gruvbox")
safe("core.plugin_config.solarized-osaka")

