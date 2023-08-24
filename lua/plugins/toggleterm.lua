return {
  { 
    'akinsho/toggleterm.nvim', 
    commit = '2a787c426ef00cb3488c11b14f5dcf892bbd0bda',
    opts = {
      size = 10,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = false,
      shading_factor = 1,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "horizontal",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 10,
        highlights = {
          border = "Normal",
          background = "Normal",
        }
      }
    },
    init = function()
      function _G.set_terminal_keymaps()
        local opts = {noremap = true}
        vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
        -- Close window on double escape
        vim.api.nvim_buf_set_keymap(0, 't', '<esc><esc>', '<cmd>close<cr>', opts)
      end
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
    end
  }
}
