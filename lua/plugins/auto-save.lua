return {
  {
    'Pocco81/auto-save.nvim',
    opts = {
      enabled = true,
      trigger_events = { "BufLeave", "WinLeave", "WinClose", "FocusLost" },
      debounce_delay = 120,
     	condition = function(buf)
        local fn = vim.fn
        local utils = require("auto-save.utils.data")
        if
          fn.getbufvar(buf, "&modifiable") == 1 and
          utils.not_in(fn.getbufvar(buf, "&filetype"), {}) then
          return true -- met condition(s), can save
		    end
		    return false -- can't save
	    end,
      write_all_buffers = false,
      execution_message = {
        dim = 0.18,
        cleaning_interval = 5000,
        message = function()
          return "";
        end,
      }
    }
  }
}
