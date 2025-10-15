local M = {}

function M:debug()
  local dap_python = require("dap-python")
  dap_python.test_class()
end

function M:debug_test()
  local dap_python = require("dap-python")
  dap_python.test_class()
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
