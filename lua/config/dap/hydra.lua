local project = require('config.project')
local is_windows = vim.loop.os_uname().version:match('Windows')
local is_hydra_installed, Hydra = pcall(require, 'hydra')
local debug_hydra = nil

local M = {
  sep = is_windows and '\\' or '/',
  default_settings = {
    debug_port = 5005,
  },
  settings = nil;
};

M.settings = project.load_project_settings('debug', M.default_settings)

-- Use telescope for selecting the debug port with descriptions
M.select_debug_port = function()
  local telescope = require('telescope')
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local sorters = require('telescope.sorters')
  local actions_state = require('telescope.actions.state')


  -- Port options with descriptions
  local port_options = {
    "5005 - Remote Java Debug",
    "8000 - Remote Maven Debug",
    "9229 - Node.js Debug",
    "5858 - Node.js Legacy Debug",
    "2345 - Go Delve Debug",
    "3000 - Node.js Development Server",
    "5678 - Python Debug (debugpy)",
    "7869 - Rust Debug",
    "6006 - TensorFlow Debugging (Python)",
    "9000 - PHP Debug",
    "Choose another..."
  }

  pickers.new({}, {
    prompt_title = "Select Debug Port",
    finder = finders.new_table({
      results = port_options,
    }),
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(_, map)
      map('i', '<CR>', function(prompt_bufnr)
        local selection = actions_state.get_selected_entry()
        local selection_value = selection.value
        local selected_port_str = selection_value:match("%d+")
        local port = tonumber(selected_port_str)

        if selection_value == "Choose another..." then
          vim.ui.input({ prompt = "Enter custom port number: ", default = tostring(M.settings.debug_port) }, function(input)
            port = tonumber(input)
            if port and port >= 1 and port <= 65535 then
              M.settings.debug_port = port
              vim.notify("Selected custom port: " .. port)

              -- Save the selected port to project settings
              project.save_project_settings(M.settings, 'debug')
            else
              vim.notify("Invalid port number! Please enter a number between 1 and 65535.", vim.log.levels.ERROR)
            end
          end)
        elseif port and port >= 1 and port <= 65535 then
          M.settings.debug_port = port
          vim.notify("Selected port: " .. port)

          -- Save the selected port to project settings
          project.save_project_settings(M.settings, 'debug')
        else
          vim.notify("Invalid port number! Please select or enter a valid port.", vim.log.levels.ERROR)
        end

        require('telescope.actions').close(prompt_bufnr)
      end)

      return true
    end
  }):find()
end

-- Terminate the session and close the UI
M.dap_close_all = function()
  require('dap').terminate()
  require('dapui').close()
end


if is_hydra_installed then
  -- Custom step functions to exit Hydra, perform the step, and reopen Hydra
  M.dap_step_into = function()
    require('dap').step_into()
    vim.defer_fn(function() debug_hydra:activate() end, 500)  -- Delay to reopen the Hydra
  end
  
  M.dap_step_over = function()
    require('dap').step_over()
    vim.defer_fn(function() debug_hydra:activate() end, 500)
  end
  
  M.dap_step_out = function()
    require('dap').step_out()
    vim.defer_fn(function() debug_hydra:activate() end, 500)
  end

  vim.cmd('command! DapToggleTray lua require("dapui").toggle("tray")')
  vim.cmd('command! DapToggleSidebar lua require("dapui").toggle("sidebar")')
  vim.cmd('command! DapToggleUI lua require("dapui").toggle()')
  vim.cmd('command! DapSelectDebugPort lua require("config.dap.hydra").select_debug_port()')
  vim.cmd('command! DapCloseAll lua require("config.dap.hydra").dap_close_all()')
 
  local debug_hint = [[
     
   ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────  
      ^Step^            ^Toggle^                    ^Connect^
   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────    
    _i_:  Step into    _b_:  Toggle breakpoint    _a_:  Attach
    _o_:  Step over    _r_:  Toggle repl          _Q_:  Disconnect
    _O_:  Step out    _ui_:  Toggle UI            _p_:  Select port [ %{dp} ]
    _c_:   Continue    _ut_:  Toggle tray
                     _us_:  Toggle sidebar
   
    _q_: exit
    ]]
    debug_hydra = Hydra({
      name = 'Debug',
      hint = debug_hint,
      config = {
        buffer = bufnr,
        color = 'red',
        invoke_on_body = true,
        on_enter = function()
         M.settings = project.load_project_settings('debug', M.default_settings)
        end,
        hint = {
          float_opts = {
              -- row, col, height, width, relative, and anchor should not be
              -- overridden
              style = "minimal",
              border = "rounded",
              focusable = false,
              noautocmd = true,
          },
          funcs = {
            dp = function() return tonumber(M.settings.debug_port) end,
          },
        },
      },
      mode = {'n','x'},
      body = '<leader>dh',
      heads = {
        { 'a', "<cmd>JavaDebugAttachRemote<cr>", { desc = 'attach remote', exit = true } },
        { 'Q', "<cmd>DapCloseAll<cr>", { exit = true, nowait = true, desc = 'terminate' } },
        { 'p', "<cmd>DapSelectDebugPort<cr>", { exit = true, nowait = true, desc = 'select debug port' } },
        { 'i', M.dap_step_into, { desc = 'step into', nowait = true, exit = true } },
        { 'o', M.dap_step_over, { desc = 'step over', nowait = true, exit = true} },
        { 'O', M.dap_step_out, { desc = 'step out', nowait = true, exit = true} },
        { 'c', "<cmd>DapContinue<cr>", { desc = 'continue', nowait = true, exit = true} },
        { 'b', "<cmd>DapToggleBreakpoint<cr>", { desc = 'toggle breakpoint', nowait = tru, exit = false} },
        { 'r', "<cmd>DapToggleRepl<cr>", { desc = 'toggle repl', exit = false} },
        { 'ui', "<cmd>DapToggleUI<cr>", { desc = 'toggle ui', nowait = true, exit = false} },
        { 'ut', "<cmd>DapToggleTray<cr>", { desc = 'toggle tray', exit = false} },
        { 'us', "<cmd>DapToggleSidebar<cr>", { desc = 'toggle sidebar', exit = false} },
        { 'q', nil, { exit = true, nowait = true, desc = 'exit' } },
      }
    })
  end

return M;
