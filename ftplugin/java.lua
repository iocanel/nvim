-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {
  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  cmd = {

    -- 💀
    'java', -- or '/path/to/java17_or_newer/bin/java'
            -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',

    -- 💀
    '-jar', '/opt/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.6.500.v20230717-2134.jar',
         -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
         -- Must point to the                                                     Change this to
         -- eclipse.jdt.ls installation                                           the actual version


    -- 💀
    '-configuration', '/opt/eclipse.jdt.ls/config_linux',
                    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
                    -- Must point to the                      Change to one of `linux`, `win` or `mac`
                    -- eclipse.jdt.ls installation            Depending on your system.


    -- 💀
    -- See `data directory configuration` section in the README
    '-data', '/home/iocanel/.local/nvim/lsp/eclipse.jdt.ls/data'
  },

  -- 💀
  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir
  root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'}),

  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {
      maxConcurrentBuilds = 1,
      autobuild = {
        enabled = false
      },
      import = {
        maven = {
          enabled = true
        },
        exclusions = {
          "**/node_modules/**",
          "**/.metadata/**",
          "**/archetype-resources/**",
          "**/META-INF/maven/**"
        }
      },
      configuration = {
        updateBuildConfiguration = "automatic",
        checkProjectSettingsExclusions = true,
        runtimes = {
           {
            name = "JavaSE-1.8",
            path = "/home/iocanel/.sdkman/candidates/java/8.0.282-open"
          },
          {
            name = "JavaSE-11",
            path = "/home/iocanel/.sdkman/candidates/java/11.0.12-tem"            
          },
          {
            name = "JavaSE-17",
            path = "/home/iocanel/.sdkman/candidates/java/17.0.7-tem",
            default = true
          },
          {
            name = "JavaSE-19",
            path = "/home/iocanel/.sdkman/candidates/java/19.0.2-tem"
          }
        },
      },
      project = {
        importHint = true,
        importOnFirstTimeStartup = "automatic",
        referencedLibraries = {
          "lib/**"
        },
        resourceFilters = {
          "node_modules",
          "\\.git",
          ".metadata",
          "archetype-resources",
          "META-INF/maven"
        }
      },
      server = {
        launchMode = "Hybrid"
      },
      contentProvider = {
        preferred = "fernflower"
      },
      completion = {
                guessMethodArguments = true,
        overwrite = true,
        enabled = true,
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.Assume.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.junit.jupiter.api.Assumptions.*",
          "org.junit.jupiter.api.DynamicContainer.*",
          "org.junit.jupiter.api.DynamicTest.*",
          "org.mockito.Mockito.*",
          "org.mockito.ArgumentMatchers.*",
          "org.mockito.Answers.*"
        }
      }
    }
  },

  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = {}
  },
}
-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
require('jdtls').start_or_attach(config)
