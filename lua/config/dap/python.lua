local M = {}

function M:debug()
  local dap = require("dap")

  -- Get current file path
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end

  -- Verify it's a Python file
  if not bufname:match("%.py$") then
    vim.notify("Current buffer is not a Python file", vim.log.levels.ERROR)
    return
  end

  -- Get project root
  local project_root = vim.fn.getcwd()

  local launch_config = {
    type = "python",
    request = "launch",
    name = "Debug Python File",
    program = bufname,
    console = "integratedTerminal",
    cwd = project_root,
  }

  dap.run(launch_config)
end

function M:debug_test()
  local dap = require("dap")

  -- Get current file path
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end

  -- Verify it's a Python test file
  if not bufname:match("%.py$") then
    vim.notify("Current buffer is not a Python file", vim.log.levels.ERROR)
    return
  end

  -- Get project root
  local project_root = vim.fn.getcwd()

  -- Check for pytest
  local pytest_path = project_root .. "/pytest.ini"
  local has_pytest = vim.fn.filereadable(pytest_path) == 1 or vim.fn.executable("pytest") == 1

  local launch_config
  if has_pytest then
    launch_config = {
      type = "python",
      request = "launch",
      name = "Debug Python Test with pytest",
      module = "pytest",
      args = {bufname, "-v"},
      console = "integratedTerminal",
      cwd = project_root,
    }
  else
    -- Fallback to unittest
    launch_config = {
      type = "python",
      request = "launch",
      name = "Debug Python Test",
      program = bufname,
      console = "integratedTerminal",
      cwd = project_root,
      args = {"-m", "unittest", "-v"},
    }
  end

  dap.run(launch_config)
end

-- DAP Interface Implementation
function M.is_filetype_supported(filetype, filename)
  return filetype == "python" or (filename and filename:match("%.py$"))
end

function M.is_test_file(filename)
  if not filename then return false end
  -- Python test patterns: test_*.py, *_test.py, or in tests/ directory
  return filename:match("test_.*%.py$") or filename:match(".*_test%.py$") or filename:find("/tests/")
end

function M.is_in_test_function(filename, line_no)
  if not M.is_test_file(filename) then
    return false, nil
  end

  -- Search upward from current line to find test function
  for i = line_no, math.max(1, line_no - 50), -1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""

    -- Python test methods: def test_*
    local test_name = line:match("def%s+(test_%w*)%(")
    if test_name then
      return true, test_name
    end
  end

  return false, nil
end

function M.get_debug_command()
  return "PythonDebug"
end

function M.get_debug_test_command()
  return "PythonDebugTest"
end

-- Python doesn't currently support specific test function debugging
function M.get_debug_test_function_command()
  return nil
end

-- Register vim commands
vim.cmd("command! PythonDebug lua require('config.dap.python'):debug()")
vim.cmd("command! PythonDebugTest lua require('config.dap.python'):debug_test()")

return M
