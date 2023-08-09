return {
  { 
    'nvim-treesitter/nvim-treesitter',
    commit = "8e763332b7bf7b3a426fd8707b7f5aa85823a5ac",
    init = function()
      -- Disable notifications to prevent 'All parsers are up-to-date!' message
      require('config.editor').notifications_off()

      -- PATCH: in order to address the message:
      -- vim.treesitter.query.get_query() is deprecated, use vim.treesitter.query.get() instead. :help deprecated
      --   This feature will be removed in Nvim version 0.10
      local orig_notify = vim.notify
      local filter_notify = function(text, level, opts)
        -- more specific to this case
        if type(text) == "string" and (string.find(text, "get_query", 1, true) or string.find(text, "get_node_text", 1, true)) then
        -- for all deprecated and stack trace warnings
        -- if type(text) == "string" and (string.find(text, ":help deprecated", 1, true) or string.find(text, "stack trace", 1, true)) then
          return
        end
        orig_notify(text, level, opts)
      end
      vim.notify = filter_notify

      --
      -- Prefer git for donwloading parsers
      --
      require("nvim-treesitter.install").prefer_git = true

      -- 
      -- Setup custom dir
      --
      local parser_dir='/home/iocanel/.local/.share/nvim/treesitter/parsers'
      vim.opt.runtimepath:append(parser_dir)
      require('nvim-treesitter.configs').setup({
        -- Add languages to be installed here that you want installed for treesitter
        ensure_installed = { 'c', 'cpp', 'java', 'go', 'lua', 'python', 'rust', 'javascript', 'typescript', 'help', 'vim', 'json', 'yaml', 'toml' },
        sync_install = false,
        auto_install = false,
        parser_install_dir=parser_dir,
        highlight = { enable = true },
        additional_vim_regex_highlighting = false,
        indent = { enable = true, disable = { 'python' } },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-q>',
            node_incremental = '<C-q>',
            scope_incremental = 'false',
            node_decremental = '<C-d>',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'V', -- linewise
              ['@class.outer'] = '<c-v>', -- blockwise
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = '@class.outer',
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[['] = '@class.outer',
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
            },
          }
        }
      })
    end,
    config = function()
      -- pcall(require('nvim-treesitter.install').update { with_sync = true })
      -- Re-enable notifications now
      require('config.editor').notifications_on()
    end
  },
  -- Additional text objects via treesitter
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    commit="2fb97bd6c53d78517d2022a0b84422c18ce5686e",
    priority = 40, -- lower priority than nvim-treesitter (50)
  }
}
