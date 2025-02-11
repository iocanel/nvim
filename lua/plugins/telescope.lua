return {
  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
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
    'nvim-telescope/telescope-fzf-native.nvim', commit = 'fab3e2212e206f4f8b3bbaa656e129443c9b802e',
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
    commit = '92598143f8c4cadb47f5aef3f7775932827df8f2',
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
    commit = '6e51d7da30bd139a6950adf2a47fda6df9fa06d2',
    config = function()
      require("telescope").load_extension("ui-select")
    end
  },
 -- Telescope Undo
  {
    'debugloop/telescope-undo.nvim',
    commit = '3dec002ea3e7952071d26fbb5d01e2038a58a554',
    config = function()
      require('telescope').load_extension("undo")
    end
  }

}
