local M = {}

-- Standard interface for DAP language modules:
-- Each module should implement:
-- - is_filetype_supported(filetype, filename) -> boolean
-- - is_test_file(filename) -> boolean  
-- - is_in_test_function(filename, line_no) -> boolean, test_name
-- - get_debug_command() -> string (command for regular debugging)
-- - get_debug_test_command() -> string (command for test debugging)
-- - get_debug_test_function_command() -> string|nil (command for specific test function, optional)

-- Discover and load all DAP language modules
local function get_dap_modules()
  local modules = {}
  local dap_config_path = vim.fn.stdpath("config") .. "/lua/config/dap"

  -- Get all .lua files in the dap config directory
  local files = vim.fn.glob(dap_config_path .. "/*.lua", false, true)

  for _, file in ipairs(files) do
    local filename = vim.fn.fnamemodify(file, ":t:r") -- Get filename without extension

    -- Skip dwim.lua and other non-language modules
    if filename ~= "dwim" and filename ~= "hydra" and filename ~= "dump" then
      local ok, module = pcall(require, "config.dap." .. filename)
      if ok and module and type(module) == "table" then
        modules[filename] = module
      end
    end
  end

  return modules
end

-- Find the appropriate DAP module for current file
local function find_dap_module()
  local filetype = vim.bo.filetype
  local filename = vim.api.nvim_buf_get_name(0)
  local modules = get_dap_modules()

  for name, module in pairs(modules) do
    if type(module) == "table" and module.is_filetype_supported then
      local ok, supported = pcall(module.is_filetype_supported, filetype, filename)
      if ok and supported then
        return module, name
      end
    end
  end

  return nil, nil
end

-- Check if current file is applicable for debugging
function M.is_applicable(file_name)
  if not file_name or file_name == "" then
    return false
  end

  local module = find_dap_module()
  return module ~= nil
end

-- Check if current file is a test file
function M.is_test_file(file_name)
  local filename = file_name or vim.api.nvim_buf_get_name(0)
  local module = find_dap_module()

  if module and module.is_test_file then
    return module.is_test_file(filename)
  end

  return false
end

-- Check if cursor is in a test method/function
function M.is_test_method(file_name, line_no)
  local filename = file_name or vim.api.nvim_buf_get_name(0)
  local line_no = line_no or vim.api.nvim_win_get_cursor(0)[1]
  local module = find_dap_module()

  if module and module.is_in_test_function then
    return module.is_in_test_function(filename, line_no)
  end

  return false, nil
end

-- Main DWIM logic
function M.debug_dwim()
  local module, module_name = find_dap_module()

  if not module then
    vim.notify("Unsupported file type for debugging", vim.log.levels.ERROR)
    return
  end

  local filename = vim.api.nvim_buf_get_name(0)
  
  -- Check if current file has any breakpoints, if not set one at current line
  local dap = require("dap")
  local breakpoints = dap.list_breakpoints() or {}
  local current_file_has_breakpoint = false
  
  for _, bp_list in pairs(breakpoints) do
    if type(bp_list) == "table" then
      for _, bp in ipairs(bp_list) do
        if bp.file and bp.file == filename then
          current_file_has_breakpoint = true
          break
        end
      end
    end
    if current_file_has_breakpoint then break end
  end
  
  if not current_file_has_breakpoint then
    dap.set_breakpoint()
  end
  local is_test = false
  local in_test_function, test_function_name = false, nil

  -- Safely call is_test_file
  if module.is_test_file then
    local ok, result = pcall(module.is_test_file, filename)
    if ok then
      is_test = result
    end
  end

  -- Safely call is_in_test_function
  if module.is_in_test_function then
    local ok, in_test, test_name = pcall(module.is_in_test_function, filename, vim.api.nvim_win_get_cursor(0)[1])
    if ok then
      in_test_function, test_function_name = in_test, test_name
    end
  end

  -- Determine which command to run
  local command = nil
  local context = module_name or "unknown"

  if is_test then
    -- Check if module supports specific test function debugging
    if in_test_function and test_function_name and module.get_debug_test_function_command then
      local ok, cmd = pcall(module.get_debug_test_function_command)
      if ok and cmd then
        command = cmd
        context = context .. " test function (" .. test_function_name .. ")"
      end
    end

    -- Fallback to general test debugging if no specific function command
    if not command and module.get_debug_test_command then
      local ok, cmd = pcall(module.get_debug_test_command)
      if ok and cmd then
        command = cmd
        context = context .. " test"
      end
    end
  else
    -- Use regular debugging
    if module.get_debug_command then
      local ok, cmd = pcall(module.get_debug_command)
      if ok and cmd then
        command = cmd
        context = context .. " program"
      end
    end
  end

  if command then
    vim.cmd(command)
  else
    vim.notify("No debug command available for " .. context, vim.log.levels.WARN)
  end
end

-- Register the DWIM command
vim.cmd("command! DebugDwim lua require('config.dap.dwim').debug_dwim()")

return M
