-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = '/home/iocanel/.cache/nvim/jdtls/data/' .. project_name

-- Find the latest Lombok JAR
local lombok_jar_list = vim.fn.split(vim.fn.glob("/home/iocanel/.m2/repository/org/projectlombok/lombok/*/lombok-*.jar", 1), "\n")
table.sort(lombok_jar_list)  -- Sort versions
local lombok_jar = #lombok_jar_list > 0 and lombok_jar_list[#lombok_jar_list] or nil

local launcher_jar = vim.fn.glob("/home/iocanel/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar", 1)

local config = {
  -- The command that starts the language server
--  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
--  
--  /home/iocanel/.vscode/extensions/redhat.java-1.40.0-linux-x64/jre/21.0.6-linux-x86_64/bin/java 
  --  --add-modules=ALL-SYSTEM 
  --  --add-opens java.base/java.util=ALL-UNNAMED 
  --  --add-opens java.base/java.lang=ALL-UNNAMED 
  --  --add-opens java.base/sun.nio.fs=ALL-UNNAMED 
  --  -Declipse.application=org.eclipse.jdt.ls.core.id1 
  --  -Dosgi.bundles.defaultStartLevel=4 
  --  -Declipse.product=org.eclipse.jdt.ls.core.product 
  --  -Djava.import.generatesMetadataFilesAtProjectRoot=false 
  --  -DDetectVMInstallationsJob.disabled=true 
  --  -Dfile.encoding=utf8 
  --  -XX:+UseParallelGC 
  --  -XX:GCTimeRatio=4 
  --  -XX:AdaptiveSizePolicyWeight=90 
  --  -Dsun.zip.disableMemoryMapping=true 
  --  -Xmx1G 
  --  -Xms100m 
  --  -Xlog:disable 
  --  -javaagent:/home/iocanel/.vscode/extensions/redhat.java-1.40.0-linux-x64/lombok/lombok-1.18.36.jar 
  --  -XX:+HeapDumpOnOutOfMemoryError 
  --  -XX:HeapDumpPath=/home/iocanel/.config/Code/User/workspaceStorage/84e3648a41ba8f3364fb9bc34a2dfeaf/redhat.java 
  --  -Daether.dependencyCollector.impl=bf 
  --  -jar /home/iocanel/.vscode/extensions/redhat.java-1.40.0-linux-x64/server/plugins/org.eclipse.equinox.launcher_1.6.1000.v20250131-0606.jar 
  --  -configuration /home/iocanel/.config/Code/User/globalStorage/redhat.java/1.40.0/config_linux 
  --  -data /home/iocanel/.config/Code/User/workspaceStorage/84e3648a41ba8f3364fb9bc34a2dfeaf/redhat.java/jdt_ws 
  --  --pipe=/run/user/1000/lsp-20381af389549d3e8cff28c4e40f57c9.sock
  cmd = {
    -- Using the script -- Disabled: I wanted project per workspace and custom jvm tuning
    --     '/home/iocanel/.local/share/nvim/mason/bin/jdtls',
    --     '-javaagent:' .. lombok_jar,
    --
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Djava.import.generatesMetadataFilesAtProjectRoot=false',
    '-DDetectVMInstallationsJob.disabled=true',
    '-Dfile.encoding=utf8',
    '-XX:+UseParallelGC',
    '-XX:GCTimeRatio=4',
    '-XX:AdaptiveSizePolicyWeight=90',
    '-Dsun.zip.disableMemoryMapping=true',
    '-Xmx1G',
    '-Xms100m',
    '-Xlog:disable',
    '-javaagent:' .. lombok_jar,
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '--add-opens', 'java.base/sun.nio.fs=ALL-UNNAMED',
    -- 💀
    --
    -- JFR
    '-XX:+FlightRecorder',
    '-XX:FlightRecorderOptions=stackdepth=128',
    -- 💀
    '-jar', launcher_jar,
    -- 💀
    '-configuration', '/home/iocanel/.local/share/nvim/mason/packages/jdtls/config_linux',
    -- See `data directory configuration` section in the README
    '-data', workspace_dir,
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
        },
        -- ✅ Ensure java.util is ranked higher than Guava in auto-imports
        preferredPackages = {
          "java.util",
          "java.util.concurrent",
          "java.util.stream"
        },
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

local project_config_updated = false

-- Mark that JDTLS needs an update when saving pom.xml
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "pom.xml", "mvnw", "mvnw.cmd", ".mvn/**/*" },
  callback = function()
    project_config_updated = true
  end
})

-- Perform JDTLS update when entering a Java buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.java",
  callback = function()
    if project_config_updated then
      project_config_updated = false
      vim.cmd("JdtUpdateConfig")
      vim.cmd("LspRestart")
    end
  end
})
