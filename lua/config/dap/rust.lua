local M = {}

-- Helper function to find Cargo.toml
local function find_cargo_root()
  local current_dir = vim.fn.expand('%:p:h')
  while current_dir ~= "/" do
    if vim.fn.filereadable(current_dir .. "/Cargo.toml") == 1 then
      return current_dir
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end
  return vim.fn.getcwd() -- fallback
end

-- Helper function to get the current package name from Cargo.toml
local function get_package_name()
  local cargo_root = find_cargo_root()
  local cargo_toml = cargo_root .. "/Cargo.toml"
  
  if vim.fn.filereadable(cargo_toml) == 1 then
    local lines = vim.fn.readfile(cargo_toml)
    for _, line in ipairs(lines) do
      local name = line:match('^name%s*=%s*"([^"]+)"')
      if name then
        return name
      end
    end
  end
  
  return nil
end

function M:debug()
  local dap = require("dap")
  
  -- Get current file path
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end
  
  -- Verify it's a Rust file
  if not bufname:match("%.rs$") then
    vim.notify("Current buffer is not a Rust file", vim.log.levels.ERROR)
    return
  end
  
  local cargo_root = find_cargo_root()
  local package_name = get_package_name()
  
  if not package_name then
    vim.notify("Could not determine package name from Cargo.toml", vim.log.levels.ERROR)
    return
  end
  
  local launch_config = {
    type = "codelldb",
    request = "launch",
    name = "Debug Rust Binary",
    program = function()
      -- Build first, then return the executable path
      vim.fn.system("cd " .. cargo_root .. " && cargo build")
      return cargo_root .. "/target/debug/" .. package_name
    end,
    cwd = cargo_root,
    stopOnEntry = false,
    args = {},
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
  
  -- Verify it's a Rust file
  if not bufname:match("%.rs$") then
    vim.notify("Current buffer is not a Rust file", vim.log.levels.ERROR)
    return
  end
  
  local cargo_root = find_cargo_root()
  
  -- For Rust tests, we'll use cargo test with a specific test binary
  local launch_config = {
    type = "codelldb", 
    request = "launch",
    name = "Debug Rust Tests",
    program = function()
      -- Build test binary first
      vim.fn.system("cd " .. cargo_root .. " && cargo build --tests")
      
      -- Try to find the test executable in target/debug/deps/
      local package_name = get_package_name()
      if not package_name then
        vim.notify("Could not determine package name", vim.log.levels.ERROR)
        return ""
      end
      
      -- Look for test executables that match the package name pattern
      local deps_dir = cargo_root .. "/target/debug/deps"
      local handle = vim.uv.fs_scandir(deps_dir)
      if handle then
        while true do
          local name, type = vim.uv.fs_scandir_next(handle)
          if not name then break end
          
          -- Look for executable files that start with the package name
          if type == "file" and name:match("^" .. package_name:gsub("-", "_")) then
            local full_path = deps_dir .. "/" .. name
            -- Check if it's executable (simple check - file exists)
            if vim.fn.executable(full_path) == 1 then
              return full_path
            end
          end
        end
      end
      
      -- Fallback: construct expected path
      return cargo_root .. "/target/debug/deps/" .. package_name:gsub("-", "_")
    end,
    cwd = cargo_root,
    stopOnEntry = false,
    args = {},
  }
  
  dap.run(launch_config)
end

-- DAP Interface Implementation
function M.is_filetype_supported(filetype, filename)
  return filetype == "rust" or (filename and filename:match("%.rs$"))
end

function M.is_test_file(filename)
  if not filename then return false end
  
  -- In Rust, tests can be in the same file as the code, but we'll check for:
  -- 1. Files with "test" in the name
  -- 2. Files in tests/ directory (but not if it's just in any tests path)
  -- 3. Files in src/ that we'll check content for test modules
  
  -- Get just the filename part for test pattern matching
  local basename = vim.fn.fnamemodify(filename, ":t")
  if basename:match("test.*%.rs$") or basename:match(".*_test%.rs$") then
    return true
  end
  
  -- Check if it's specifically in a Cargo project's tests/ directory
  -- (not just any tests directory in the path)
  local relative_to_cargo = filename:match("/tests/[^/]*%.rs$")
  return relative_to_cargo ~= nil
end

function M.is_in_test_function(filename, line_no)
  -- Search upward from current line to find test function
  for i = line_no, math.max(1, line_no - 50), -1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
    
    -- Rust test functions: #[test] annotation followed by fn
    if line:match("#%[test%]") then
      -- Look for function definition in next few lines
      for j = i, math.min(vim.api.nvim_buf_line_count(0), i + 5) do
        local fn_line = vim.api.nvim_buf_get_lines(0, j - 1, j, false)[1] or ""
        local fn_name = fn_line:match("fn%s+(%w+)%s*%(")
        if fn_name then
          return true, fn_name
        end
      end
      return true, nil
    end
    
    -- Direct pattern: #[test] on same line as function
    local test_fn = line:match("#%[test%].-fn%s+(%w+)%s*%(")
    if test_fn then
      return true, test_fn
    end
  end
  
  -- Also check if we're inside a #[cfg(test)] module
  for i = line_no, math.max(1, line_no - 100), -1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
    if line:match("#%[cfg%(test%)%]") then
      -- We're in a test module, check if current function is a test
      for j = line_no, math.max(1, line_no - 20), -1 do
        local fn_line = vim.api.nvim_buf_get_lines(0, j - 1, j, false)[1] or ""
        local fn_name = fn_line:match("fn%s+(%w+)%s*%(")
        if fn_name then
          return true, fn_name
        end
      end
    end
  end
  
  return false, nil
end

function M.get_debug_command()
  return "RustDebug"
end

function M.get_debug_test_command()
  return "RustDebugTest"
end

-- Rust doesn't currently support specific test function debugging easily
function M.get_debug_test_function_command()
  return nil
end

-- Check available debuggers
local function get_available_debugger()
  if vim.fn.executable('codelldb') == 1 then
    return 'codelldb'
  elseif vim.fn.executable('rust-gdb') == 1 then
    return 'rust-gdb'
  elseif vim.fn.executable('gdb') == 1 then
    return 'gdb'
  else
    return nil
  end
end

-- Setup DAP configurations
local function setup_dap_configurations()
  local dap = require("dap")
  local debugger = get_available_debugger()
  
  if not debugger then
    -- Create minimal config to satisfy tests but warn about missing debugger
    dap.configurations.rust = {
      {
        name = "Rust Debug (no debugger available)",
        type = "rust-debug",
        request = "launch",
        program = function()
          vim.notify("No Rust debugger found. Install one of: codelldb, rust-gdb, or gdb", vim.log.levels.WARN)
          return ""
        end,
        cwd = "${workspaceFolder}",
      }
    }
    return
  end
  
  if debugger == 'codelldb' then
    -- Rust adapter configuration for codelldb
    dap.adapters.codelldb = {
      type = 'server',
      port = "${port}",
      executable = {
        command = 'codelldb',
        args = {"--port", "${port}"},
      }
    }
    
    -- Rust debug configurations for codelldb
    dap.configurations.rust = {
      {
        name = "Launch Rust Program (codelldb)",
        type = "codelldb",
        request = "launch",
        program = function()
          local cargo_root = find_cargo_root()
          local package_name = get_package_name()
          if not package_name then
            vim.notify("Could not determine package name", vim.log.levels.ERROR)
            return ""
          end
          vim.fn.system("cd " .. cargo_root .. " && cargo build")
          return cargo_root .. "/target/debug/" .. package_name
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      },
      {
        name = "Debug Rust Tests (codelldb)",
        type = "codelldb",
        request = "launch", 
        program = function()
          local cargo_root = find_cargo_root()
          vim.fn.system("cd " .. cargo_root .. " && cargo build --tests")
          
          local package_name = get_package_name()
          if not package_name then
            vim.notify("Could not determine package name", vim.log.levels.ERROR)
            return ""
          end
          
          -- Look for test executables that match the package name pattern
          local deps_dir = cargo_root .. "/target/debug/deps"
          local handle = vim.uv.fs_scandir(deps_dir)
          if handle then
            while true do
              local name, type = vim.uv.fs_scandir_next(handle)
              if not name then break end
              
              -- Look for executable files that start with the package name
              if type == "file" and name:match("^" .. package_name:gsub("-", "_")) then
                local full_path = deps_dir .. "/" .. name
                -- Check if it's executable (simple check - file exists)
                if vim.fn.executable(full_path) == 1 then
                  return full_path
                end
              end
            end
          end
          
          -- Fallback: construct expected path
          return cargo_root .. "/target/debug/deps/" .. package_name:gsub("-", "_")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      }
    }
  else
    -- GDB-based debugging (rust-gdb or gdb)
    dap.adapters["rust-gdb"] = {
      type = "executable",
      command = debugger,
      args = {"-i", "dap"}
    }
    
    dap.configurations.rust = {
      {
        name = "Launch Rust Program (" .. debugger .. ")",
        type = "rust-gdb",
        request = "launch",
        program = function()
          local cargo_root = find_cargo_root()
          local package_name = get_package_name()
          if not package_name then
            vim.notify("Could not determine package name", vim.log.levels.ERROR)
            return ""
          end
          vim.fn.system("cd " .. cargo_root .. " && cargo build")
          return cargo_root .. "/target/debug/" .. package_name
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      },
      {
        name = "Debug Rust Tests (" .. debugger .. ")",
        type = "rust-gdb",
        request = "launch", 
        program = function()
          local cargo_root = find_cargo_root()
          vim.fn.system("cd " .. cargo_root .. " && cargo build --tests")
          
          local package_name = get_package_name()
          if not package_name then
            vim.notify("Could not determine package name", vim.log.levels.ERROR)
            return ""
          end
          
          -- Look for test executables that match the package name pattern
          local deps_dir = cargo_root .. "/target/debug/deps"
          local handle = vim.uv.fs_scandir(deps_dir)
          if handle then
            while true do
              local name, type = vim.uv.fs_scandir_next(handle)
              if not name then break end
              
              -- Look for executable files that start with the package name
              if type == "file" and name:match("^" .. package_name:gsub("-", "_")) then
                local full_path = deps_dir .. "/" .. name
                -- Check if it's executable (simple check - file exists)
                if vim.fn.executable(full_path) == 1 then
                  return full_path
                end
              end
            end
          end
          
          -- Fallback: construct expected path
          return cargo_root .. "/target/debug/deps/" .. package_name:gsub("-", "_")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      }
    }
  end
end

-- Setup configurations when module is loaded
setup_dap_configurations()

-- Register vim commands
vim.cmd("command! RustDebug lua require('config.dap.rust'):debug()")
vim.cmd("command! RustDebugTest lua require('config.dap.rust'):debug_test()")

return M