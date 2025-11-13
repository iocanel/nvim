local M = {
  default_settings = {
    debug_port = 5005,
  },
  settings = nil;
};

function M:attach_to_remote(port)
  local project = require('config.project')
  M.settings = project.load_project_settings('debug', M.default_settings)
  port = port or M.settings.debug_port or 5005
  local dap = require('dap')

  local module_name = project.get_module_name()
  dap.configurations.java = {
    {
      type = 'java';
      request = 'attach';
      name = "Attach to the process";
      hostName = 'localhost';
      port = port;
      projectName = module_name;
    },
  }
  dap.continue()
end

-- Function to search for .classpath file in the current directory or parent directories
local function find_classpath_file(start_dir)
  local dir = start_dir or vim.fn.getcwd()
  while dir ~= "/" do
    local classpath_file = dir .. "/.classpath"
    if vim.loop.fs_stat(classpath_file) then
      return classpath_file
    end
    dir = vim.fn.fnamemodify(dir, ":h") -- Move up one directory
  end
  return nil
end

-- Function to get the fully qualified class name from the current file
local function get_current_class()
  local bufname = vim.api.nvim_buf_get_name(0)
  local class_name = bufname:match("([^/]+)%.java$")
  return class_name or "UnknownClass"
end

function M:debug()
  local dap = require("dap")
  local jdtls = require("jdtls") -- Ensure jdtls is loaded

  -- Ensure jdtls is initialized
  if not jdtls or not jdtls.setup_dap then
    vim.notify("jdtls is not available. Ensure it is installed and running.", vim.log.levels.ERROR)
    return
  end

  -- Setup DAP
  jdtls.setup_dap({ hotcodereplace = "auto" })

  -- Get current file class and package info
  local bufname = vim.api.nvim_buf_get_name(0)
  local class_name = bufname:match("([^/]+)%.java$")
  if not class_name then
    vim.notify("Current buffer is not a Java file", vim.log.levels.ERROR)
    return
  end

  -- Determine package from file path
  local package = vim.fn.expand("%:p:h"):gsub("[/\\]", "."):gsub("^.*src[./\\]main[./\\]java[./\\]", ""):gsub("^.*src[./\\]test[./\\]java[./\\]", "")
  local fqcn = package ~= "" and (package .. "." .. class_name) or class_name

  -- Get project name using the proper module detection
  local project = require('config.project')
  local module_name = project.get_module_name()


  -- Create and run a specific launch configuration without user interaction
  local launch_config = {
    type = 'java',
    request = 'launch',
    name = "Launch " .. fqcn,
    mainClass = fqcn,
    projectName = module_name,
  }

  dap.run(launch_config)
end

function M:debug_test()
  local jdtls = require("jdtls")
  -- Ensure jdtls is available
  if not jdtls or not jdtls.test_class then
    vim.notify("jdtls is not available or test_class function not found. Ensure jdtls is properly configured with test bundles.", vim.log.levels.ERROR)
    return
  end
  -- Get current file info to verify it's a Java file
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("%.java$") then
    vim.notify("Current buffer is not a Java file", vim.log.levels.ERROR)
    return
  end
  jdtls.test_class()
end

function M:debug_test_method()
  local jdtls = require("jdtls")
  -- Ensure jdtls is available
  if not jdtls or not jdtls.test_nearest_method then
    vim.notify("jdtls is not available or test_nearest_method function not found. Ensure jdtls is properly configured with test bundles.", vim.log.levels.ERROR)
    return
  end
  -- Get current file info to verify it's a Java file
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("%.java$") then
    vim.notify("Current buffer is not a Java file", vim.log.levels.ERROR)
    return
  end
  jdtls.test_nearest_method()
end

vim.cmd("command! JavaDebug lua require('config.dap.java'):debug()")
vim.cmd("command! JavaDebugTest lua require('config.dap.java'):debug_test()")
vim.cmd("command! JavaDebugTestMethod lua require('config.dap.java'):debug_test_method()")
vim.cmd('command! JavaDebugAttachRemote lua require("config.dap.java").attach_to_remote()')

local dap_ok, dap = pcall(require, "dap")
if dap_ok then
  dap.configurations.java = {
    {
      type = 'java',
      request = 'attach',
      name = "Attach to Remote Java Process (port 5005)",
      hostName = 'localhost',
      port = 5005,
    },
    {
      type = 'java',
      request = 'attach',
      name = "Attach to Remote Java Process (custom port)",
      hostName = 'localhost',
      port = function()
        return tonumber(vim.fn.input('Debug port: ', '5005'))
      end,
    },
    {
      type = 'java',
      request = 'launch',
      name = "Launch Current Java Class",
      mainClass = function()
        -- Get current file class name
        local bufname = vim.api.nvim_buf_get_name(0)
        local class_name = bufname:match("([^/]+)%.java$")
        if class_name then
          -- Try to determine package from file path
          local package = vim.fn.expand("%:p:h"):gsub("[/\\]", "."):gsub("^.*src[./\\]main[./\\]java[./\\]", ""):gsub("^.*src[./\\]test[./\\]java[./\\]", "")
          if package and package ~= "" then
            return package .. "." .. class_name
          else
            return class_name
          end
        end
        return vim.fn.input('Main class: ', '')
      end,
      projectName = function()
        local project = require('config.project')
        return project.get_module_name()
      end,
    }
  }
end
-- DAP Interface Implementation
local dap_setup_done = false

function M.setup_dap()
  local jdtls = require("jdtls")
  if not jdtls or not jdtls.setup_dap then
    return false
  end
  
  -- Skip if already done
  if dap_setup_done then
    print("✅ DAP already set up, skipping...")
    return true
  end
  
  -- Step 1: Wait for JDTLS to gain full capabilities
  print("⏳ Step 1: Waiting for JDTLS to gain full capabilities...")
  local jdtls_ready = vim.wait(30000, function()
    for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
      if client.initialized then
        local caps = client.server_capabilities or {}
        -- Wait for a rich set of capabilities indicating full initialization
        local has_rich_caps = caps.documentSymbolProvider
                           and caps.referencesProvider
                           and caps.completionProvider
                           and caps.workspaceSymbolProvider
        if has_rich_caps then
          return true
        end
      end
    end
    return false
  end, 1000)
  
  if not jdtls_ready then
    print("⚠️ JDTLS didn't gain full capabilities within 30s, proceeding anyway")
  else
    print("✅ Step 1 complete: JDTLS has rich capabilities")
  end
  
  -- Step 2: Call DAP setup
  print("🔧 Step 2: Setting up JDTLS DAP...")
  jdtls.setup_dap({ hotcodereplace = "auto" })
  print("✅ Step 2 complete: DAP setup finished")
  
  dap_setup_done = true
  return true
end

function M.is_filetype_supported(filetype, filename)
  return filetype == "java" or (filename and filename:match("%.java$"))
end

function M.is_test_file(filename)
  if not filename then return false end
  -- Java test patterns: *Test.java, *Tests.java, or in test/ directory
  return filename:match("Test%.java$") or filename:match("Tests%.java$") or filename:find("/test/")
end

function M.is_in_test_function(filename, line_no)
  if not M.is_test_file(filename) then
    return false, nil
  end
  
  -- Search upward from current line to find test method
  for i = line_no, math.max(1, line_no - 50), -1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
    
    -- Java test methods: @Test annotation or method names starting with "test"
    if line:match("@Test") then
      -- Look for method definition in next few lines
      for j = i, math.min(vim.api.nvim_buf_line_count(0), i + 5) do
        local method_line = vim.api.nvim_buf_get_lines(0, j - 1, j, false)[1] or ""
        local method_name = method_line:match("void%s+(%w+)%s*%(") or method_line:match("public%s+void%s+(%w+)%s*%(")
        if method_name then
          return true, method_name
        end
      end
      return true, nil
    end
    
    -- Direct test method pattern
    local method_name = line:match("void%s+(test%w*)%s*%(") or line:match("public%s+void%s+(test%w*)%s*%(")
    if method_name then
      return true, method_name
    end
  end
  
  return false, nil
end

function M.get_debug_command()
  return "JavaDebug"
end

function M.get_debug_test_command()
  return "JavaDebugTest"
end

-- Java supports specific test method debugging
function M.get_debug_test_function_command()
  return "JavaDebugTestMethod"
end

return M;
