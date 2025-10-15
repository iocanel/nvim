return {
  {
    'williamboman/mason.nvim',
    opts = {
    }
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      ensure_installed = { 'html', 'cssls', 'jsonls', 'ts_ls', 'vue-langage-server', 'js-debug-adapter', 'lua_ls', 'rust_analyzer', 'gopls', 'ts_ls', 'pyright', 'solidity', 'intelephense', 'ltex', 'clangd', 'codelldb' },
      automatic_installation = true,
    },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      lspconfig.lua_ls.setup{
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = {'vim'},
            }
          }
        }
      }
      lspconfig.gopls.setup { capabilities = capabilities }
      lspconfig.pyright.setup { capabilities = capabilities }
      lspconfig.html.setup { capabilities = capabilities }
      lspconfig.ts_ls.setup {
        capabilities = capabilities,
        filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "typescript.tsx", "vue" },
        init_options = {
          plugins = {
            {
              name = '@vue/typescript-plugin',
              location = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server',
              languages = { 'vue' }
            }
          }
        },
        settings = {
          typescript = {
            tsserver = {
              useSyntaxServer = false,
            },
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayVariableTypeHintsWhenTypeMatchesName = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            }
          }
        }
      }
      lspconfig.volar.setup {
        capabilities = capabilities,
        init_options = {
          vue = {
            hybridMode = false,
          },
        },
        settings = {
          typescript = {
            inlayHints = {
              enumMemberValues = {
                enabled = true,
              },
              functionLikeReturnTypes = {
                enabled = true,
              },
              propertyDeclarationTypes = {
                enabled = true,
              },
              parameterTypes = {
                enabled = true,
                suppressWhenArgumentMatchesName = true,
              },
              variableTypes = {
                enabled = true,
              },
            },
          },
        },
      }
      lspconfig.rust_analyzer.setup { capabilities = capabilities }
      lspconfig.clangd.setup { capabilities = capabilities }
      lspconfig.intelephense.setup {
        capabilities = capabilities,
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
      lspconfig.ltex.setup({
        filetypes = { "markdown", "text", "asciidoc", "org" },
        settings = {
          ltex = {
            language = "en-US",
            additionalRules = {
              enablePickyRules = true,
              motherTongue = "en",
            },
            disabledRules = {
              ["en-US"] = { "WHITESPACE_RULE" }
            },
            dictionary = {
              ["en-US"] = {}, -- you can add custom words here
            }
          },
        },
      })
    end
  },
}
