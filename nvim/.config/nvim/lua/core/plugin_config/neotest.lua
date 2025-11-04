local log_path = vim.fn.stdpath('cache') .. '/neotest_error.log'
local function log_err(msg)
  local f = io.open(log_path, 'a')
  if f then
    f:write(os.date('%Y-%m-%d %H:%M:%S') .. ' ' .. msg .. '\n')
    f:close()
  end
  vim.schedule(function()
    vim.api.nvim_echo({{msg, 'ErrorMsg'}}, true, {})
  end)
end

-- Attempt setup (can be called multiple times safely)
local function attempt_setup()
  local ok_neotest, neotest = pcall(require, 'neotest')
  if not ok_neotest then return end
  local ok_go, neotest_go = pcall(require, 'neotest-go')
  if not ok_go then return end
  local ok_setup, setup_err = pcall(function()
    neotest.setup({ adapters = { neotest_go({}) } })
  end)
  if not ok_setup then
    log_err('neotest.setup failed: ' .. tostring(setup_err))
  end
end

local function safe_neotest(fn)
  local ok, nt = pcall(require, 'neotest')
  if not ok then
    vim.notify('neotest not loaded', vim.log.levels.ERROR)
    return
  end
  if not nt.run then
    -- Try to set up adapters now
    attempt_setup()
    local ok2, nt2 = pcall(require, 'neotest')
    if not ok2 or not nt2.run then
      vim.notify('neotest run interface unavailable', vim.log.levels.ERROR)
      return
    end
    nt = nt2
  end
  fn(nt)
end

local function neotest_totals()
  local ok, nt = pcall(require, 'neotest')
  if not ok then return '' end
  if not nt.summary or not nt.summary.get_stats then return '' end
  local stats = nt.summary.get_stats()
  if not stats then return '' end
  return string.format('P:%d F:%d S:%d', stats.passed or 0, stats.failed or 0, stats.skipped or 0)
end

-- Keymaps (always defined)
vim.keymap.set('n', '<leader>tn', function() safe_neotest(function(nt) nt.run.run() end) end, { desc = 'Run nearest test' })
vim.keymap.set('n', '<leader>tf', function() safe_neotest(function(nt) nt.run.run(vim.fn.expand('%')) end) end, { desc = 'Run all tests in file' })
vim.keymap.set('n', '<leader>tl', function() safe_neotest(function(nt) nt.run.run_last() end) end, { desc = 'Re-run last test' })
vim.keymap.set('n', '<leader>to', function() safe_neotest(function(nt) nt.output.open() end) end, { desc = 'Open test output' })
vim.keymap.set('n', '<leader>ts', function() safe_neotest(function(nt) nt.summary.toggle() end) end, { desc = 'Toggle test summary' })
vim.keymap.set('n', '<leader>tp', function() safe_neotest(function(nt) nt.run.run('.') end) end, { desc = 'Run all tests in current package' })
vim.keymap.set('n', '<leader>ta', function() safe_neotest(function(nt) nt.run.run({ suite = true }) end) end, { desc = 'Run entire test suite' })

-- Initial attempt (non-blocking)
attempt_setup()

-- Retry after packer sync completes
vim.api.nvim_create_autocmd('User', {
  pattern = 'PackerComplete',
  callback = function()
    attempt_setup()
  end,
})
