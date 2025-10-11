local M = {}

function M:debug()
  local dap = require("dap")
  
  -- Get current file path
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end
  
  -- Verify it's a TypeScript file
  if not bufname:match("%.ts$") then
    vim.notify("Current buffer is not a TypeScript file", vim.log.levels.ERROR)
    return
  end
  
  -- Get project root
  local project_root = vim.fn.getcwd()
  
  print("Debugging TypeScript file: " .. bufname)
  
  -- Enhanced configuration for better lambda/anonymous function debugging
  local launch_config = {
    type = "pwa-node",
    request = "launch",
    name = "Debug TypeScript File",
    runtimeExecutable = "node",
    runtimeArgs = {
      "-r", "ts-node/register",   -- hook ts-node
      "--inspect-brk",            -- pause on entry
      bufname,                    -- your current .ts file
    },
    cwd = project_root,
    console = "integratedTerminal",
    internalConsoleOptions = "neverOpen",
    -- Only skip Node.js internals, not user code
    skipFiles = {
      "<node_internals>/**/*.js",
      project_root .. "/node_modules/**/*.js",   -- skip all node_modules
    },
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

function M:debug_test()
  local dap = require("dap")
  
  -- Get current file path
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end
  
  -- Verify it's a TypeScript test file
  if not bufname:match("%.ts$") then
    vim.notify("Current buffer is not a TypeScript file", vim.log.levels.ERROR)
    return
  end
  
  -- Get project root
  local project_root = vim.fn.getcwd()
  
  print("Debugging TypeScript test file: " .. bufname)
  
  -- Check if Jest is available in the project
  local jest_path = project_root .. "/node_modules/jest/bin/jest.js"
  if vim.fn.filereadable(jest_path) == 1 then
    -- Use Jest configuration with TypeScript support
    local launch_config = {
      type = "pwa-node",
      request = "launch",
      name = "Debug TypeScript Test File",
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
    -- Fallback to direct ts-node execution with enhanced debugging
    local launch_config = {
      type = "pwa-node",
      request = "launch",
      name = "Debug TypeScript Test File",
      runtimeExecutable = "node",
      runtimeArgs = {
        "-r", "ts-node/register",   -- hook ts-node
        "--inspect-brk",            -- pause on entry
        bufname,                    -- your current .ts file
      },
      cwd = project_root,
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
      sourceMaps = true,
      skipFiles = {
        "<node_internals>/**/*.js",
        project_root .. "/node_modules/**/*.js",   -- skip all node_modules
      },
      -- Better handling of anonymous functions
      showAsyncStacks = true,
    }
    dap.run(launch_config)
  end
end

-- Create Vim commands
vim.cmd("command! TypescriptDebug lua require('config.dap.typescript'):debug()")
vim.cmd("command! TypescriptDebugTest lua require('config.dap.typescript'):debug_test()")

return M