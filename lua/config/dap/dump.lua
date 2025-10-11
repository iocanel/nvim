local M = {};

-- Function to dump DAP configurations to file
local function dump_dap_config()
  local dap = require('dap')
  local home = os.getenv("HOME")
  local xdg_data_home = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
  local config_dir = xdg_data_home .. '/nvim/dap'
  local config_file = config_dir .. '/current.config'
  
  -- Ensure directory exists
  vim.fn.mkdir(config_dir, 'p')
  
  -- Convert dap configurations to readable format
  local config_str = vim.inspect(dap.configurations, {
    indent = "  ",
    depth = 10
  })
  
  -- Also get adapters info
  local adapters_str = vim.inspect(dap.adapters, {
    indent = "  ",
    depth = 10
  })
  
  -- Write to file
  local file = io.open(config_file, 'w')
  if file then
    file:write("-- DAP Configuration dump\n")
    file:write("-- Generated on: " .. os.date() .. "\n\n")
    file:write("-- DAP Configurations:\n")
    file:write("dap.configurations = " .. config_str .. "\n\n")
    file:write("-- DAP Adapters:\n")
    file:write("dap.adapters = " .. adapters_str .. "\n")
    file:close()
    vim.notify("DAP config dumped to: " .. config_file, vim.log.levels.INFO)
  else
    vim.notify("Failed to write DAP config to: " .. config_file, vim.log.levels.ERROR)
  end
end

-- Make the function available in the module
M.dump_dap_config = dump_dap_config

-- Add command to dump DAP config
vim.cmd('command! DapDumpConfig lua require("config.dap.dump").dump_dap_config()')

return M;
