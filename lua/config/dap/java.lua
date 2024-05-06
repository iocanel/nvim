local M = {
};

function M:attach_to_remote(port)
  port = port or 5005
  local dap = require('dap')
  dap.configurations.java = {
    {
      type = 'java';
      request = 'attach';
      name = "Attach to the process";
      hostName = 'localhost';
      port = port;
    },
  }
  dap.continue()
end

vim.cmd('command! JavaDebugAttachRemote lua require("config.dap.java").attach_to_remote()')
return M;
