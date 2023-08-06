return {
  { 
    'gbrlsnchs/winpick.nvim', commit = '044623e236750a2f61a2cb96ce0833e113921b88', 
    keys = { 
      { 
        "<leader>wp", 
        function()
          local winpick = require('winpick')
          local winid = winpick.select()
          if winid then
  	        vim.api.nvim_set_current_win(winid)
          end
        end, 
        desc = 'window pick' 
      }, 
      { 
        "<leader>wk", 
        function()
          local winpick = require('winpick')
          local winid = winpick.select()
          if winid then
            vim.api.nvim_win_close(winid, true)
          end
        end, 
        desc = 'window kill' 
      } 
    }
  }
}
