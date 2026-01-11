return {
  { 
    "lewis6991/gitsigns.nvim", 
    commit = "v0.9.0", 
    opts = {
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      }
    },
    init = function()
      local is_hydra_installed, Hydra = pcall(require, 'hydra')
      if is_hydra_installed then
        local git_hint = [[
        _n_: next hunk   _s_: stage hunk        _d_: show deleted   _b_: blame line
        _p_: prev hunk   _r_: reset hunk        _v_: preview hunk   _B_: blame show full
        ^ ^              _u_: unstage hunk      _w_: word diff      _l_: line highlight
        ^ ^              _S_: stage buffer      _D_: diff this      _/_: show base file
        ^ ^              _R_: reset buffer      ^ ^                 ^ ^
        ^
        ^ ^              _<Enter>_: Neogit              _q_: exit
        ]]
        Hydra({
          name = 'Git',
          hint = git_hint,
          config = {
            buffer = bufnr,
            color = 'red',
            invoke_on_body = true,
            hint = {
              float_opts = {
                  -- row, col, height, width, relative, and anchor should not be
                  -- overridden
                  style = "minimal",
                  border = "rounded",
                  focusable = false,
                  noautocmd = true,
              },
            },
          },
          mode = {'n','x'},
          body = '<leader>gH',
          heads = {
            { 'n', "<cmd>Gitsigns next_hunk<cr>", { desc = 'next hunk', exit = false } },
            { 'p', "<cmd>Gitsigns prev_hunk<cr>", { desc = 'prev hunk', exit = false} },
            { 's', "<cmd>Gitsigns stage_hunk<cr>", { silent = true, desc = 'stage hunk' } },
            { 'r', "<cmd>Gitsigns reset_hunk<cr>", { silent = true, desc = 'reset hunk' } },
            { 'u', "<cmd>Gitsigns undo_stage_hunk<cr>", { desc = 'undo last stage' } },
            { 'S', "<cmd>Gitsigns stage_buffer<cr>", { desc = 'stage buffer' } },
            { 'R', "<cmd>Gitsigns reset_buffer<cr>", { desc = 'reset buffer' } },
            { 'v', "<cmd>Gitsigns preview_hunk<cr>", { desc = 'preview hunk' } },
            { 'd', "<cmd>Gitsigns toggle_deleted<cr>", { nowait = true, desc = 'toggle deleted' } },
            { 'D', "<cmd>Gitsigns diffthis<cr>", { desc = 'diff this' } },
            { 'w', "<cmd>Gitsigns toggle_word_diff<cr>", { desc = 'toggle word diff' } },
            { 'l', "<cmd>Gitsigns toggle_linehl<cr>", { desc = 'toggle line highlight' } },
            { 'b', "<cmd>Gitsigns blame_line<cr>", { desc = 'blame' } },
            { 'B', function() gitsigns.blame_line{ full = true } end, { desc = 'blame show full' } },
            { '/', "<cmd>Gitsigns show<cr>", { exit = true, desc = 'show base file' } }, -- show the base of the file
            { '<Enter>', '<cmd>Neogit<cr>', { exit = true, desc = 'Neogit' } },
            { 'q', nil, { exit = true, nowait = true, desc = 'exit' } },
          }
        })
      end
    end
  }
}
