local jdtls_home = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
local jdtls_bin = jdtls_home .. "/bin/jdtls"
local jdtls_jar = jdtls_home .. "/plugins/jdtls/"

function jdtls_project_data_dir()
    local root_dir = vim.fs.dirname(vim.fs.find({'.gradlew', '.git', 'mvnw'}, { upward = true })[1]);
    if root_dir == nil then
       return nil;
    else
     return root_dir .. '/.lsp/data';
    end
end

local lspconfig = require('lspconfig')
lspconfig['jdtls'].setup {
  cmd = {
    -- 💀
    'java', -- or '/path/to/java17_or_newer/bin/java'
            -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-jar', '/home/iocanel/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar',
    -- 💀
    '-configuration', '/home/iocanel/.local/share/nvim/mason/packages/jdtls/config_linux',
    '-data', jdtls_project_data_dir()
  }
}

local opts = {
  cmd = {},
  settings = {
    java = {
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {},
        filteredTypes = {
          -- "com.sun.*",
          -- "io.micrometer.shaded.*",
          -- "java.awt.*",
          -- "jdk.*",
          -- "sun.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
      configuration = {
        runtimes = {
          {
            name = "JavaSE-1.8",
            path = "/home/iocanel/.sdkman/candidates/java/8.0.282-open",
            default = true,
          },
          {
            name = "JavaSE-11",
            path = "/home/iocanel/.sdkman/candidates/java/11.0.17-open",
          },
          {
            name = "JavaSE-17",
            path = "/home/iocanel/.sdkman/candidates/java/17.0.1-tem",
          },
        },
      },
    },
  },
}

local function setup()
  local jdtls_installed, jdtls = pcall(require, "jdtls")
  if not jdtls_installed then
    print "jdtls not installed"
    return {}
  end

  require("jdtls")
  print "check"
  local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
  local jdtls_bin = jdtls_path .. "/bin/jdtls"

  local root_markers = { ".gradle", "gradlew", ".git" }
  local root_dir = jdtls.setup.find_root(root_markers)
  local home = os.getenv("HOME")
  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

  opts.cmd = {
    jdtls_bin,
    "-data",
    workspace_dir,
  }
  local common_opts = require("lsp").get_common_options()

  local on_attach = function(client, bufnr)
    jdtls.setup.add_commands()
    -- vim.lsp.codelens.refresh()
    -- if JAVA_DAP_ACTIVE then
    jdtls.setup_dap({ hotcodereplace = "auto" })
    jdtls.dap.setup_dap_main_class_configs()
    -- end
    common_opts.on_attach(client, bufnr)
  end

  opts.on_attach = on_attach
  opts.capabilities = common_opts.capabilities
  return opts
end

return { setup = setup }
