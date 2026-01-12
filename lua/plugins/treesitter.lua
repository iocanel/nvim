-- Code Tree Support / Syntax Highlighting
return {
  -- https://github.com/nvim-treesitter/nvim-treesitter
  'nvim-treesitter/nvim-treesitter',
  event = 'VeryLazy',
  build = ':TSUpdate',
  opts = {
    highlight = {
      enable = true,
    },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<C-e>',
        node_incremental = '<C-e>',
        node_decremental = '<C-s>',
      },
    },

    auto_install = false, -- automatically install syntax support when entering new file type buffer
    ensure_installed = {
      'java',
      'javascript',
      'typescript',
      'python',
      'go',
      'rust',
      'lua',
      'html',
      'css',
    },
  },
  config = function (_, opts)
    require("nvim-treesitter.config").setup(opts)
  end
}
