return {
  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      defaults = {
        mappings = {
          i = {
            ['<C-u>'] = false,
            ['<C-d>'] = false,
          },
        },
      }
    },
    init = function()
    end
  },
  -- Telescope FZF
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    build = 'make', cond =  vim.fn.executable 'make' == 1,
    config = function() 
      local telescope = require('telescope')
      pcall(telescope.load_extension, 'fzf')
    end
  },
  -- Telescope Zoxide
  {
    'jvgrootveld/telescope-zoxide',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    commit = '856af0d83d2e167b5efa080567456c1578647abe',
    config = function()
      local telescope = require('telescope')
       pcall(telescope.load_extension, 'zoxide')
    end
  },
  -- Telescope Repo
  {
    'cljoly/telescope-repo.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      local telescope = require('telescope')
      local repo_ext_installed, repo = pcall(telescope.load_extension, 'repo')
      if repo_ext_installed then
        telescope.setup {
          extensions = {
            repo = {
              list = {
                fd_opts = {
                  "--no-ignore-vcs",
                },
                search_dirs = {
                  "~/workspace",
                },
              },
            },
          },
        }
      end
    end
  },
  -- Telescope UI Select
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require("telescope").load_extension("ui-select")
    end
  },
 -- Telescope Undo
  {
    'debugloop/telescope-undo.nvim',
--    commit = '3dec002ea3e7952071d26fbb5d01e2038a58a554',
    config = function()
      require('telescope').load_extension("undo")
    end
  }

}
