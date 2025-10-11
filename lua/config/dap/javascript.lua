local M = {}

function M:debug_file()
  local dap = require("dap")
  
  -- Get current file path
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end
  
  -- Verify it's a JavaScript file
  if not bufname:match("%.js$") then
    vim.notify("Current buffer is not a JavaScript file", vim.log.levels.ERROR)
    return
  end
  
  -- Get project root
  local project_root = vim.fn.getcwd()
  
  print("Debugging JavaScript file: " .. bufname)
  
  -- Enhanced configuration for better lambda/anonymous function debugging
  local launch_config = {
    type = "pwa-node",
    request = "launch",
    name = "Debug JavaScript File",
    program = bufname,
    cwd = project_root,
    console = "integratedTerminal",
    -- Only skip Node.js internals, not user code
    skipFiles = { "<node_internals>/**" },
    -- Enable source maps for better debugging
    sourceMaps = true,
    -- Smart stepping to handle anonymous functions better
    smartStep = true,
    -- Resolve source maps properly
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**"
    },
    -- Better handling of anonymous functions
    showAsyncStacks = true,
    -- Enable trace logging for debugging issues (can be disabled in production)
    trace = false,
  }
  
  dap.run(launch_config)
end

function M:debug_test_file()
  local dap = require("dap")
  
  -- Get current file path
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end
  
  -- Verify it's a JavaScript test file
  if not bufname:match("%.js$") then
    vim.notify("Current buffer is not a JavaScript file", vim.log.levels.ERROR)
    return
  end
  
  -- Get project root
  local project_root = vim.fn.getcwd()
  
  print("Debugging JavaScript test file: " .. bufname)
  
  -- Check if Jest is available in the project
  local jest_path = project_root .. "/node_modules/jest/bin/jest.js"
  if vim.fn.filereadable(jest_path) == 1 then
    -- Use Jest configuration (same as the working "Debug Jest Tests" config)
    local launch_config = {
      type = "pwa-node",
      request = "launch",
      name = "Debug JavaScript Test File",
      runtimeExecutable = "node",
      runtimeArgs = {
        "./node_modules/jest/bin/jest.js",
        "--runInBand",
        "--inspect-brk",              -- pause before tests run
        bufname,                      -- only this test file
      },
      cwd = project_root,
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**/*.js" },
    }
    dap.run(launch_config)
  else
    -- Fallback to direct Node execution with enhanced debugging
    local launch_config = {
      type = "pwa-node",
      request = "launch",
      name = "Debug JavaScript Test File",
      runtimeExecutable = "node",
      runtimeArgs = {
        "--inspect-brk",
        bufname,
      },
      cwd = project_root,
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**/*.js" },
      -- Better handling of anonymous functions
      showAsyncStacks = true,
    }
    dap.run(launch_config)
  end
end

-- Create Vim commands
vim.cmd("command! JavascriptDebugFile lua require('config.dap.javascript'):debug_file()")
vim.cmd("command! JavascriptDebugTestFile lua require('config.dap.javascript'):debug_test_file()")

return M