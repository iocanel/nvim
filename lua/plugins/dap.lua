return {
  -- nvim-dap
  {
    "mfussenegger/nvim-dap",
    commit = "6ae8a14828b0f3bff1721a35a1dfd604b6a933bb",
    dependencies = {
      "leoluz/nvim-dap-go",
      "mxsdev/nvim-dap-vscode-js",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
    init = function()
      -- Set breakpoint icons
      vim.fn.sign_define('DapBreakpoint', { text='', texthl='red', linehl='', numhl='' })
      vim.fn.sign_define('DapStopped', { text='→', texthl='green', linehl='', numhl= '' })
      vim.fn.sign_define('DapBreakpointRejected', { text='', texthl='red', linehl='', numhl= '' })

      -- Let's define the particular keymap here, instead of in keymaps.lua because I only want it to be active when dap is loaded.
      -- If we move it to keymaps.lua, it will possibly cause issues when dap is not yet full loaded (lsp initialized).
      vim.keymap.set('n', '<LeftMouse>', "<LeftMouse><cmd>lua require('dapui').bp_mouse_toggle()<cr>", {desc = "dap toggle breakpoint"})
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
    local dap, dapui = require("dap"), require("dapui")
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

      function dapui.bp_mouse_toggle()
        local buf = vim.api.nvim_get_current_buf()
        local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
        local is_file = buftype == ''
        if not is_file then
          return
        end
        -- Fix issues with table.unpack falling back to the global unpack
        if not table.unpack then
          table.unpack = unpack
        end
        local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_buf_get_lines(buf, row-1, row, false)[1]
        if col == 0 and line ~= "" then
            require('dap').toggle_breakpoint()
        end
      end
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
  },
  -- dap-python
  {
    -- https://github.com/mfussenegger/nvim-dap-python
    'mfussenegger/nvim-dap-python',
    ft = 'python',
    dependencies = {
      -- https://github.com/mfussenegger/nvim-dap
      'mfussenegger/nvim-dap',
    },
    config = function ()
      -- Update the path passed to setup to point to your system or virtual env python binary
      require('dap-python').setup('python3')
    end
  },
  -- dap-go
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = {
      "mfussenegger/nvim-dap"
    },
    config = function()
      require("dap-go").setup()
    end
  },

  -- Credits to: https://github.com/nikolovlazar/dotfiles/blob/92c91ed035348c74e387ccd85ca19a376ea2f35e/.config/nvim/lua/plugins/dap.lua
  -- Install the vscode-js-debug adapter
  {
    "microsoft/vscode-js-debug",
    -- After install, build it and rename the dist directory to out
    build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
    version = "1.*",
  },
  -- nvim-dap-vscode-js
  {
    "mxsdev/nvim-dap-vscode-js",
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" },
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap = require("dap")

      -- let the plugin register all pwa-* adapters for you
      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "pwa-extensionHost", "node-terminal" },
        log_file_level = vim.log.levels.DEBUG,
      })

      -- Keep only the Attach configuration - file launch handled by dedicated config files
      for _, lang in ipairs({ "javascript", "typescript" }) do
        dap.configurations[lang] = {
          -- Attach
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require'dap.utils'.pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end,
  }
}
