return {
  {
    'neovim/nvim-lspconfig',
--     commit = "0eecf453d33248e9d571ad26559f35175c37502d",
     commit = "3ea99227e316c5028f57a4d86a1a7fd01dd876d0",
     dependencies = {
      -- Automatically install LSPs to stdpath for neovim
--      'williamboman/mason.nvim',
--      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      'j-hui/fidget.nvim',

      -- Additional lua configuration, makes nvim stuff amazing
      'folke/neodev.nvim',
     },
    config = function()
      -- LSP semantic tokens enabled - especially important for Java
      -- where treesitter highlighting is minimal
    -- Fix LspInfo related errors
    local util = require("lspconfig.util")
    -- if util._trim is missing, alias it to the old name
    util._trim = util._trim or util._trim_and_pad
    end
  },
  {
    'hrsh7th/cmp-nvim-lsp',
    commit = '44b16d11215dce86f253ce0c30949813c0a90765',
    dependencies = {
      'hrsh7th/nvim-cmp'
    },
    opts = {
      sources = {
        { name = 'nvim_lsp' }
      }
    },
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
    end
  }
}
