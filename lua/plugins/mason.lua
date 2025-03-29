return {
  {
    'williamboman/mason.nvim',
    commit = 'fc98833b6da5de5a9c5b1446ac541577059555be',
    opts = {
    }
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    commit = '1a31f824b9cd5bc6f342fc29e9a53b60d74af245',
    opts = {
      ensure_installed = { 'html', 'cssls', 'jsonls', 'sumneko_lua', 'rust_analyzer', 'gopls', 'tsserver', 'pyright', 'solidity', 'intelephense' },
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
    end
  },
}
