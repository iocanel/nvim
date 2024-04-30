return {
  -- dap-ui
  {
    "rcarriga/nvim-dap-ui",
    commit = "5934302d63d1ede12c0b22b6f23518bb183fc972",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio"
    },
    config = function()
      -- NOTE: Check out this for guide
      -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
      dofile(vim.g.base46_cache .. "dap")
      local dap = require "dap"
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })

      local dapui = require "dapui"
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      -- Java --
      dap.configurations.java = {
        {
          name = "Launch Java",
          javaExec = "java",
          request = "launch",
          type = "java",
        },
        {
          type = 'java',
          request = 'attach',
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 5005,
        },
      }
    end
  }
}
