local M = {}

-- Function to get the current Go package path
local function get_current_package()
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("%.go$") then
    return "."
  end
  
  -- Get directory of current file
  local dir = vim.fn.fnamemodify(bufname, ":p:h")
  
  -- Find go.mod to determine module root
  local current_dir = dir
  while current_dir ~= "/" do
    if vim.loop.fs_stat(current_dir .. "/go.mod") then
      -- Found module root, return relative path from module root
      local rel_path = dir:sub(#current_dir + 2) -- +2 to remove the leading slash
      return rel_path == "" and "." or rel_path
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end
  
  -- Fallback to current directory
  return "."
end

-- Function to get the current test function name
local function get_current_test_function()
  local line = vim.api.nvim_get_current_line()
  local test_func = line:match("func%s+(Test%w+)")
  if test_func then
    return test_func
  end
  
  -- Search upward for test function
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  for i = cursor_line, 1, -1 do
    local current_line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
    test_func = current_line:match("func%s+(Test%w+)")
    if test_func then
      return test_func
    end
  end
  
  return nil
end

-- Debug current Go program
function M.debug_program()
  local dap = require("dap")
  
  -- Ensure we're in a Go file
  if vim.bo.filetype ~= "go" then
    vim.notify("Current buffer is not a Go file", vim.log.levels.ERROR)
    return
  end
  
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname:match("_test%.go$") then
    vim.notify("Use GoDebugTest for test files", vim.log.levels.WARN)
    return
  end
  
  -- Clear existing breakpoints and set one at current line if none exist
  local breakpoints = dap.list_breakpoints() or {}
  if vim.tbl_isempty(breakpoints) then
    dap.set_breakpoint()
  end
  
  local config = {
    type = "go",
    name = "Debug Go Program",
    request = "launch",
    program = "${file}",
    mode = "debug",
  }
  
  print("Debugging Go program: " .. vim.fn.fnamemodify(bufname, ":t"))
  dap.run(config)
end

-- Debug current Go test
function M.debug_test()
  local dap = require("dap")
  
  -- Ensure we're in a Go file
  if vim.bo.filetype ~= "go" then
    vim.notify("Current buffer is not a Go file", vim.log.levels.ERROR)
    return
  end
  
  local package_path = get_current_package()
  
  -- Clear existing breakpoints and set one at current line if none exist
  local breakpoints = dap.list_breakpoints() or {}
  if vim.tbl_isempty(breakpoints) then
    dap.set_breakpoint()
  end
  
  local config = {
    type = "go",
    name = "Debug Go Tests",
    request = "launch",
    program = package_path,
    mode = "test",
    args = {"-test.v"},
  }
  
  print("Debugging all Go tests in package: " .. package_path)
  dap.run(config)
end

-- Debug specific Go test function
function M.debug_test_function()
  local dap = require("dap")
  
  -- Ensure we're in a Go file
  if vim.bo.filetype ~= "go" then
    vim.notify("Current buffer is not a Go file", vim.log.levels.ERROR)
    return
  end
  
  local bufname = vim.api.nvim_buf_get_name(0)
  local package_path = get_current_package()
  
  -- Try to detect current test function
  local test_func = get_current_test_function()
  if not test_func then
    if bufname:match("_test%.go$") then
      vim.notify("Could not detect test function. Place cursor inside a test function.", vim.log.levels.WARN)
    else
      vim.notify("Not in a test file. Use GoDebug for regular Go files.", vim.log.levels.WARN)
    end
    return
  end
  
  -- Clear existing breakpoints and set one at current line if none exist
  local breakpoints = dap.list_breakpoints() or {}
  if vim.tbl_isempty(breakpoints) then
    dap.set_breakpoint()
  end
  
  local config = {
    type = "go",
    name = "Debug Test: " .. test_func,
    request = "launch",
    program = package_path,
    mode = "test",
    args = {"-test.v", "-test.run", "^" .. test_func .. "$"},
  }
  
  print("Debugging Go test function: " .. test_func)
  dap.run(config)
end

-- Setup Go DAP configuration
local function setup_go_dap()
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return
  end
  
  -- Basic Go DAP configurations
  dap.configurations.go = {
    {
      type = "go",
      name = "Debug Current Go Program",
      request = "launch",
      program = "${file}",
      mode = "debug",
    },
    {
      type = "go", 
      name = "Debug Go Tests in Package",
      request = "launch",
      program = ".",
      mode = "test",
      args = {"-test.v"},
    },
    {
      type = "go",
      name = "Debug Specific Test Function",
      request = "launch", 
      program = ".",
      mode = "test",
      args = function()
        local test_name = vim.fn.input("Test function name (without Test prefix): ")
        if test_name == "" then
          return {"-test.v"}
        end
        return {"-test.v", "-test.run", "^Test" .. test_name .. "$"}
      end,
    },
    {
      type = "go",
      name = "Attach to Remote Process",
      mode = "remote",
      request = "attach",
      remotePath = "${workspaceFolder}",
      port = function()
        return tonumber(vim.fn.input("Debug port: ", "2345"))
      end,
      host = "127.0.0.1",
    },
  }
end

-- Initialize DAP configuration when module is loaded
setup_go_dap()

-- Register vim commands
vim.cmd("command! GoDebug lua require('config.dap.go').debug_program()")
vim.cmd("command! GoDebugTest lua require('config.dap.go').debug_test()")
vim.cmd("command! GoDebugTestFunction lua require('config.dap.go').debug_test_function()")

-- DAP Interface Implementation
function M.is_filetype_supported(filetype, filename)
  return filetype == "go" or (filename and filename:match("%.go$"))
end

function M.is_test_file(filename)
  if not filename then return false end
  -- Go test patterns: *_test.go
  return filename:match("_test%.go$")
end

function M.is_in_test_function(filename, line_no)
  if not M.is_test_file(filename) then
    return false, nil
  end
  
  -- Search upward from current line to find test function
  for i = line_no, math.max(1, line_no - 50), -1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
    
    -- Go test functions: func Test*(t *testing.T)
    local test_func = line:match("func%s+(Test%w+)%(")
    if test_func then
      return true, test_func
    end
  end
  
  return false, nil
end

function M.get_debug_command()
  return "GoDebug"
end

function M.get_debug_test_command()
  return "GoDebugTest"
end

-- Go supports specific test function debugging
function M.get_debug_test_function_command()
  return "GoDebugTestFunction"
end

return M