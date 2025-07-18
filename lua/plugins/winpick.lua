local M = {
  window_next = function()
    local current_win = vim.fn.win_getid()
    local all_wins = vim.fn.getwininfo()
    local next_win = nil

    for i, win in ipairs(all_wins) do
      if win.winid == current_win then
        next_win = all_wins[(i % #all_wins) + 1]
        break
      end
    end

    if next_win then
      vim.fn.win_gotoid(next_win.winid)
    end
  end
};

return {
  {
    'gbrlsnchs/winpick.nvim', commit = '044623e236750a2f61a2cb96ce0833e113921b88',
    init = function()
      window_next = function()
        local current_win = vim.fn.win_getid()
        local all_wins = vim.fn.getwininfo()
        local next_win = nil

        for i, win in ipairs(all_wins) do
          if win.winid == current_win then
            next_win = all_wins[(i % #all_wins) + 1]
            break
          end
        end

        if next_win then
          vim.fn.win_gotoid(next_win.winid)
        end
      end
    vim.cmd('command! WinpickNext lua window_next()')
    end,
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
      },
      {
        "<leader>wn", "<cmd>WinpickNext<cr>", desc = 'window next'
      },
      {
        "<M-o>", "<cmd>WinpickNext<cr>", desc = 'window next', mode = {"n", "i"}
      }
    }
  }
}
