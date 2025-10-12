-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.

-- Use XDG Base Directory specification with fallbacks
local home = os.getenv("HOME")
local data_dir  = vim.fn.stdpath("data")  -- e.g. /opt/xdg/data/nvim
local cache_dir = vim.fn.stdpath("cache") -- e.g. /opt/xdg/cache/nvim

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
-- JDTLS workspace uses cache directory (can be regenerated)
local workspace_dir = cache_dir .. '/jdtls/data/' .. project_name

-- Maven repository location
local m2_repo = os.getenv("MAVEN_REPOSITORY") or (home .. "/.m2/repository")

-- Mason uses data directory (persistent tools/plugins)
local mason_data = data_dir .. '/mason'

-- Function to download Maven artifact using mvn dependency:get
local function download_maven_artifact(group_id, artifact_id, version)
  local cmd = string.format("mvn dependency:get -Dartifact=%s:%s:%s", group_id, artifact_id, version)
  local result = vim.fn.system(cmd)
  return vim.v.shell_error == 0, result
end

-- Function to download file via HTTP
local function download_file_http(url, destination)
  local cmd = string.format("curl -L -o '%s' '%s'", destination, url)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error == 0 and vim.fn.filereadable(destination) == 1 then
    return true, result
  end

  -- Try with wget if curl fails
  cmd = string.format("wget -O '%s' '%s'", destination, url)
  result = vim.fn.system(cmd)
  return vim.v.shell_error == 0 and vim.fn.filereadable(destination) == 1, result
end

-- Function to ensure Maven artifact is available
local function ensure_maven_artifact(group_id, artifact_id, version, glob_pattern, central_url)
  local jar_list = vim.fn.split(vim.fn.glob(glob_pattern, 1), "\n")
  table.sort(jar_list)

  if #jar_list > 0 then
    return jar_list[#jar_list]
  end

  vim.notify(string.format("Downloading %s:%s:%s...", group_id, artifact_id, version), vim.log.levels.INFO)

  -- Try Maven first
  local success, result = download_maven_artifact(group_id, artifact_id, version)
  if success then
    jar_list = vim.fn.split(vim.fn.glob(glob_pattern, 1), "\n")
    table.sort(jar_list)
    if #jar_list > 0 then
      vim.notify(string.format("Successfully downloaded %s:%s:%s", group_id, artifact_id, version), vim.log.levels.INFO)
      return jar_list[#jar_list]
    end
  end

  -- Try HTTP download if Maven fails and URL is provided
  if central_url then
    local destination_dir = string.format("%s/%s/%s/%s",
      m2_repo, group_id:gsub("%.", "/"), artifact_id, version)
    vim.fn.mkdir(destination_dir, "p")
    local destination = string.format("%s/%s-%s.jar", destination_dir, artifact_id, version)

    success, result = download_file_http(central_url, destination)
    if success then
      vim.notify(string.format("Successfully downloaded %s:%s:%s via HTTP", group_id, artifact_id, version), vim.log.levels.INFO)
      return destination
    end
  end

  vim.notify(string.format("Failed to download %s:%s:%s", group_id, artifact_id, version), vim.log.levels.ERROR)
  return nil
end

-- Find or download Lombok JAR
local lombok_version = "1.18.36"
local lombok_glob = m2_repo .. "/org/projectlombok/lombok/*/lombok-*.jar"
local lombok_url = "https://repo1.maven.org/maven2/org/projectlombok/lombok/" .. lombok_version .. "/lombok-" .. lombok_version .. ".jar"
local lombok_jar = ensure_maven_artifact("org.projectlombok", "lombok", lombok_version, lombok_glob, lombok_url)

local launcher_jar = vim.fn.glob(mason_data .. "/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar", 1)
if launcher_jar == "" then
  vim.notify("JDTLS launcher JAR not found in Mason packages", vim.log.levels.ERROR)
  return
end

-- Function to find the latest installed Temurin JDK for a given version
local function find_temurin_jdk(version)
    local jdk_paths = vim.fn.split(vim.fn.glob("/nix/store/*-temurin-bin-" .. version .. "*/bin/java", 1), "\n")
    table.sort(jdk_paths) -- Sort to get the latest version if multiple exist

    if #jdk_paths > 0 then
        return jdk_paths[#jdk_paths]:gsub("/bin/java", "") -- Extract JDK root path
    end
    return nil
end

-- Detect Temurin JDK 21 and 23 dynamically
local jdk21_path = find_temurin_jdk("21")
local jdk23_path = find_temurin_jdk("23")

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
  -- Build command dynamically to handle optional Lombok
  cmd = vim.tbl_flatten({
    'java',
    -- 💀
    '--enable-preview',
    -- 💀

    -- Memory optimization (set min=max for better allocation)
    '-Xms2G',
    '-Xmx2G',

    -- Modern Garbage Collection for better latency
    '-XX:+UseG1GC',
    '-XX:MaxGCPauseMillis=200',
    '-XX:G1HeapRegionSize=16m',

    -- Class Data Sharing for faster startup (CDS enabled by default in Java 21+)
    '-XX:SharedArchiveFile=' .. cache_dir .. '/jdtls/classes.jsa',
    '-Xshare:auto',

    -- String and memory optimizations
    '-XX:+UseStringDeduplication',
    '-XX:+UseCompressedOops',

    -- JIT Compilation optimizations
    '-XX:+TieredCompilation',
    '-XX:TieredStopAtLevel=4',

    -- I/O and system optimizations
    '-Djava.awt.headless=true',
    '-Djava.net.preferIPv4Stack=true',

    -- Eclipse JDT LS specific settings
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Djava.import.generatesMetadataFilesAtProjectRoot=false',
    '-DDetectVMInstallationsJob.disabled=true',
    '-Dfile.encoding=utf8',
    '-Dsun.zip.disableMemoryMapping=true',
    '-Xlog:disable',

    -- Lombok agent (conditional)
    lombok_jar and ('-javaagent:' .. lombok_jar) or {},

    -- Java module system
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '--add-opens', 'java.base/sun.nio.fs=ALL-UNNAMED',

    -- JFR (Java Flight Recorder) for profiling
    '-XX:+FlightRecorder',
    '-XX:FlightRecorderOptions=stackdepth=128',
    -- 💀
    '-jar', launcher_jar,
    -- 💀
    '-configuration', mason_data .. '/packages/jdtls/config_linux',
    -- See `data directory configuration` section in the README
    '-data', workspace_dir,
  }),

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
        gradle = {
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
            name = "JavaSE-21",
            path = jdk21_path,
          },
          {
            name = "JavaSE-23",
            path = jdk23_path,
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
    bundles = (function()
      local bundles = {}

      -- Java Debug Adapter
      local debug_jar = vim.fn.glob(mason_data .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar", 1)

      -- Java Test Adapter - get all JAR files
      local test_jars = vim.fn.split(vim.fn.glob(mason_data .. "/share/java-test/**/*.jar", 1), "\n")

      if debug_jar == "" then
        -- Try to install java-debug-adapter silently via Mason
        local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
        if mason_registry_ok then
          local java_debug_pkg = mason_registry.get_package("java-debug-adapter")
          if java_debug_pkg and not java_debug_pkg:is_installed() then
            vim.notify("Installing java-debug-adapter automatically...", vim.log.levels.INFO)
            java_debug_pkg:install():once("closed", function()
              -- Re-check for the JAR after installation
              local new_debug_jar = vim.fn.glob(mason_data .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar", 1)
              if new_debug_jar ~= "" then
                vim.notify("java-debug-adapter installed successfully", vim.log.levels.INFO)
                -- Restart JDTLS to pick up the new debug adapter
                vim.defer_fn(function()
                  pcall(vim.cmd, "LspRestart jdtls")
                end, 1000)
              else
                vim.notify("java-debug-adapter installation may have failed", vim.log.levels.WARN)
              end
            end)
          end
        else
          vim.notify("Mason not available. Install java-debug-adapter manually with: :MasonInstall java-debug-adapter", vim.log.levels.WARN)
        end
      else
        table.insert(bundles, debug_jar)
        -- vim.notify("Java debug adapter found: " .. debug_jar, vim.log.levels.DEBUG)
      end

      if #test_jars == 0 then
        -- Try to install java-test silently via Mason
        local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
        if mason_registry_ok then
          local java_test_pkg = mason_registry.get_package("java-test")
          if java_test_pkg and not java_test_pkg:is_installed() then
            vim.notify("Installing java-test automatically...", vim.log.levels.INFO)
            java_test_pkg:install():once("closed", function()
              -- Re-check for the JARs after installation
              local new_test_jars = vim.fn.split(vim.fn.glob(mason_data .. "/share/java-test/**/*.jar", 1), "\n")
              if #new_test_jars > 0 then
                vim.notify("java-test installed successfully (" .. #new_test_jars .. " JARs)", vim.log.levels.INFO)
                -- Restart JDTLS to pick up the new test adapter
                vim.defer_fn(function()
                  pcall(vim.cmd, "LspRestart jdtls")
                end, 1000)
              else
                vim.notify("java-test installation may have failed", vim.log.levels.WARN)
              end
            end)
          end
        else
          vim.notify("Mason not available. Install java-test manually with: :MasonInstall java-test", vim.log.levels.WARN)
        end
      else
        -- Add ALL test JAR files
        for _, jar in ipairs(test_jars) do
          table.insert(bundles, jar)
        end
        -- vim.notify("Java test adapter found: " .. #test_jars .. " JAR files", vim.log.levels.INFO)
      end
      return bundles
    end)();
  },
}

require('jdtls').setup_dap({ hotcodereplace = 'auto' })
-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
require('jdtls').start_or_attach(config)

local project_config_updated = false
local restart_attempts = {}

-- Robust JDTLS refresh function with comprehensive error handling
local function safe_jdt_refresh()
  -- Prevent restart spam (10 second cooldown)
  local now = vim.loop.now()
  if restart_attempts[project_name] and (now - restart_attempts[project_name]) < 10000 then
    vim.notify("JDTLS restart attempted recently, skipping to prevent spam", vim.log.levels.WARN)
    return
  end
  restart_attempts[project_name] = now

  local update_ok = pcall(vim.cmd, "JdtUpdateConfig")
  if not update_ok then
    vim.notify("JdtUpdateConfig command failed", vim.log.levels.WARN)
  end

  -- Wait briefly then try restart if needed
  vim.defer_fn(function()
    local restart_ok = pcall(vim.cmd, "LspRestart jdtls")
    if not restart_ok then
      vim.notify("LspRestart failed, trying nuclear option...", vim.log.levels.WARN)

      -- Final fallback: JdtWipeDataAndRestart
      local wipe_ok = pcall(vim.cmd, "JdtWipeDataAndRestart")
      if not wipe_ok then
        vim.notify("All JDTLS refresh methods failed. Try manual restart with :JdtWipeDataAndRestart", vim.log.levels.ERROR)
      else
        vim.notify("JDTLS workspace wiped and restarted", vim.log.levels.DEBUG)
      end
    else
      vim.notify("JDTLS configuration refreshed successfully", vim.log.levels.DEBUG)
    end
  end, 1000)

  -- Timeout safety net
  vim.defer_fn(function()
    if project_config_updated then
      vim.notify("JDTLS refresh may have timed out. Consider manual restart if issues persist", vim.log.levels.WARN)
    end
  end, 30000)  -- 30 second timeout
end

-- Mark that JDTLS needs an update when saving pom.xml
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "pom.xml", "mvnw", "mvnw.cmd", ".mvn/**/*", "build.gradle", "settings.gradle", "gradlew" },
  callback = function()
    project_config_updated = true
  end
})

-- Perform JDTLS update when entering a Java buffer (with robust error handling)
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.java",
  callback = function()
    if project_config_updated then
      project_config_updated = false
      safe_jdt_refresh()
    end
  end
})

-- Function to dump JDTLS config to file
local function dump_jdtls_config()
  local config_dir = data_dir .. '/jdtls'
  local config_file = config_dir .. '/current.config'

  -- Ensure directory exists
  vim.fn.mkdir(config_dir, 'p')

  -- Convert config to readable format
  local config_str = vim.inspect(config, {
    indent = "  ",
    depth = 10
  })

  -- Write to file
  local file = io.open(config_file, 'w')
  if file then
    file:write("-- JDTLS Configuration dump\n")
    file:write("-- Generated on: " .. os.date() .. "\n\n")
    file:write("return " .. config_str)
    file:close()
    vim.notify("JDTLS config dumped to: " .. config_file, vim.log.levels.INFO)
  else
    vim.notify("Failed to write config to: " .. config_file, vim.log.levels.ERROR)
  end
end

-- Add command to dump config
vim.api.nvim_create_user_command("JdtlsDumpConfig", function() dump_jdtls_config() end, {})
