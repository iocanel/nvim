return {
  { 
    'williamboman/mason.nvim',
    commit = 'fe9e34a9ab4d64321cdc3ecab4ea1809239bb73f',
    opts = {
    }
  },
  { 
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    commit = 'e86a4c84ff35240639643ffed56ee1c4d55f538e',
    opts = {
      ensure_installed = { 'html', 'cssls', 'jsonls', 'sumneko_lua', 'rust_analyzer', 'gopls', 'tsserver' },
      automatic_installation = true,
    },
    config = function()
      local lspconfig = require('lspconfig')
      lspconfig.sumneko_lua.setup{
        settings = {
          Lua = {
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = {'vim'},
            }
          }
        }
      }
      lspconfig.pyright.setup {}
      lspconfig.tsserver.setup {}
      lspconfig.rust_analyzer.setup {}
    end
  },
}
