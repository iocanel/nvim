return {
  {
    'neovim/nvim-lspconfig',
     commit = "0eecf453d33248e9d571ad26559f35175c37502d",
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
      -- Disable highlight from Lsp as we use treesitter for highlighting
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        client.server_capabilities.semanticTokensProvider = nil
      end,
    });
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
