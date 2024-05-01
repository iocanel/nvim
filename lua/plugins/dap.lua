return {
  -- nvim-dap
  {
    "mfussenegger/nvim-dap",
    commit = "6ae8a14828b0f3bff1721a35a1dfd604b6a933bb",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap, dapui, dapvt = require("dap"), require("dapui"), require("nvim-dap-virtual-text")
      dapvt.setup()
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      -- Set breakpoint icons
      vim.fn.sign_define('DapBreakpoint', { text='', texthl='red', linehl='', numhl='' })
      vim.fn.sign_define('DapStopped', { text='', texthl='green', linehl='', numhl= '' })
      vim.fn.sign_define('DapBreakpointRejected', { text='', texthl='red', linehl='', numhl= '' })
    end
  },
  -- dap-ui
  {
    "rcarriga/nvim-dap-ui",
    commit = "f7d75cca202b52a60c520ec7b1ec3414d6e77b0f",
    dependencies = {
      "nvim-neotest/nvim-nio"
    },
    config = function()
      local dapui = require("dapui")
      dapui.setup({
      controls = {
        element = "repl",
        enabled = true,
        icons = {
          disconnect = "",
          pause = "",
          play = "",
          run_last = "",
          step_back = "",
          step_into = "",
          step_out = "",
          step_over = "",
          terminate = ""
        }
      },
      element_mappings = {},
      expand_lines = true,
      floating = {
        border = "single",
        mappings = {
          close = { "q", "<Esc>" }
        }
      },
      force_buffers = true,
      icons = {
        collapsed = "",
        current_frame = "",
        expanded = ""
      },
    layouts = { {
        elements = { {
            id = "scopes",
            size = 0.25
          }, {
            id = "breakpoints",
            size = 0.25
          }, {
            id = "stacks",
            size = 0.25
          }, {
            id = "watches",
            size = 0.25
          } },
        position = "left",
        size = 40
      }, {
        elements = { {
            id = "console",
            size = 0.5
          }, {
            id = "repl",
            size = 0.25
          } },
        position = "bottom",
        size = 10
      } },
      mappings = {
        edit = "e",
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        repl = "r",
        toggle = "t"
      },
      render = {
        indent = 1,
        max_value_lines = 100
      }
    })
    end
  },
  -- dap-virtual-text
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      show_stop_reason = true,
      commented = false,
      virt_text_pos = "eol",
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    },
  }
}
