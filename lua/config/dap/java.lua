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

function M:debug_main()
  local dap = require("dap")
  local jdtls = require("jdtls") -- Ensure jdtls is loaded
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

  -- Ensure jdtls is initialized
  if not jdtls or not jdtls.setup_dap then
    vim.notify("jdtls is not available. Ensure it is installed and running.", vim.log.levels.ERROR)
    return
  end

  -- Setup DAP
  jdtls.setup_dap({ hotcodereplace = "auto" })

  -- Get class name from current file
  local class = get_current_class()
  local package = vim.fn.expand("%:p:h"):gsub("[/\\]", "."):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")
  local fqcn = package .. "." .. class
  if package == "" then
    fqcn = class
  end

  print ("Debugging " .. fqcn)
  dap.continue()
end

vim.cmd("command! JavaDebugMain lua require('config.dap.java').debug_main()")
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
return M;
