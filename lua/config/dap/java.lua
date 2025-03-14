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

  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t') -- Extract project name
  dap.configurations.java = {
    {
      type = 'java';
      request = 'attach';
      name = "Attach to the process";
      hostName = 'localhost';
      port = port;
      projectName = project_name;
    },
  }
  dap.continue()
end

vim.cmd('command! JavaDebugAttachRemote lua require("config.dap.java").attach_to_remote()')
return M;
