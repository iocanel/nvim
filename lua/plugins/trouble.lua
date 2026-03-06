local source_buf = nil
local buffer_filter_enabled = true

return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    win = {
      position = "bottom",
      size = { height = 10 },
    },
    auto_close = true,
    follow = true,
    open_no_results = true,
    keys = {
      w = {
        action = function(view)
          view:filter({ severity = vim.diagnostic.severity.ERROR }, { toggle = true })
        end,
        desc = "toggle warnings",
      },
      f = {
        action = function()
          buffer_filter_enabled = not buffer_filter_enabled
          if buffer_filter_enabled and source_buf then
            require("trouble").close()
            require("trouble").open({ mode = "diagnostics", focus = true, filter = { buf = source_buf } })
          else
            require("trouble").close()
            require("trouble").open({ mode = "diagnostics", focus = true })
          end
        end,
        desc = "toggle current buffer filter",
      },
    },
  },
  cmd = { "Trouble" },
  keys = {
    {
      "<leader>td",
      function()
        source_buf = vim.api.nvim_get_current_buf()
        buffer_filter_enabled = true
        require("trouble").toggle({ mode = "diagnostics", focus = true, filter = { buf = source_buf } })
      end,
      desc = "toggle diagnostics",
    },
    {
      "<leader>Dt",
      function()
        source_buf = vim.api.nvim_get_current_buf()
        buffer_filter_enabled = true
        require("trouble").toggle({ mode = "diagnostics", focus = true, filter = { buf = source_buf } })
      end,
      desc = "toggle trouble",
    },
  },
}
