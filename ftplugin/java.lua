-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = '/home/iocanel/.local/share/nvim/mason/packages/jdtls/data/' .. project_name
local lombok_jar = vim.fn.glob('/home/iocanel/.m2/repository/org/projectlombok/lombok/1.18.30/lombok-1.18.30.jar')
local config = {
  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  cmd = {
       '/home/iocanel/.local/share/nvim/mason/bin/jdtls',
       '-javaagent:' .. lombok_jar,
  },

  -- 💀
  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir
  root_dir = require('jdtls.setup').find_root({'.git', 'pom.xml', 'mvnw', 'build.gralde', 'gradlew'}),

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
            name = "JavaSE-17",
            path = os.getenv("JAVA_HOME"),
            default = true
          },
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
    },
    maven = {
      downloadSources = true,
      downloadJavaDoc = true
    },
    implementationsCodeLens = {
      enabled = true
    },
    referencesCodeLens = {
      enabled = true
    },
    references = {
      includeDecompiledSources = true,
    },
  },
  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = {
      vim.fn.glob("/home/iocanel/.local/share/nvim/mason/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar", 1);
    };
  },
}
require('jdtls').setup_dap({ hotcodereplace = 'auto' })
-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
require('jdtls').start_or_attach(config)
