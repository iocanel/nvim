return {
  {
    'williamboman/mason.nvim',
    commit = 'c43eeb5614a09dc17c03a7fb49de2e05de203924',
    opts = {
    }
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    commit = 'e86a4c84ff35240639643ffed56ee1c4d55f538e',
    opts = {
      ensure_installed = { 'html', 'cssls', 'jsonls', 'sumneko_lua', 'rust_analyzer', 'gopls', 'tsserver', 'pyright', 'intelephense', 'grammarly_languageserver' },
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
      lspconfig.gopls.setup {}
      lspconfig.pyright.setup {}
      lspconfig.tsserver.setup {}
      lspconfig.rust_analyzer.setup {}
      lspconfig.intelephense.setup {
        settings = {
          intelephense = {
            stubs = {
              "bcmath",
              "bz2",
              "calendar",
              "Core",
              "curl",
              "zip",
              "zlib",
              "wordpress",
              "woocommerce",
              "acf-pro",
              "wordpress-globals",
              "wp-cli",
              "genesis",
              "polylang"
            },
            environment = {
              includePaths = '/home/iocanel/.composer/vendor/php-stubs/' -- this line forces the composer path for the stubs in case inteliphense don't find it...
            },
            files = {
              maxSize = 5000000;
            };
          };
        }
      }
      lspconfig.grammarly_languageserver.setup {}
    end
  },
}
