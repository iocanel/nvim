-- Run with:
--   nvim --headless "+luafile tests/java/dap.lua"
-- Env overrides (optional):
--   JDTLS_WAIT_MS=25000
--   DAP_WAIT_MS=20000

-- Load utilities
local luaunit = dofile("tests/lib/luaunit.lua")
local framework = dofile("tests/lib/framework.lua")
local lsp_setup = dofile("tests/lib/lsp_setup.lua")
local dap_utils = dofile("tests/lib/dap.lua")
local config = dofile("tests/java/config.lua")

-- Setup test environment
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "src/main/java/com/iocanel/App.java",
  service_file = "src/main/java/com/iocanel/GreetingService.java",
  test_file = "src/test/java/com/iocanel/GreetingServiceTest.java",
  pom_file = "pom.xml",
}

local paths = framework.setup_project_paths(this_dir, "test_project", required_files)
framework.enter_project_dir(paths.project_root)

-- Build the project using Maven wrapper (required for debugging)
print("Building project with Maven wrapper...")
local mvn_cmd = vim.fn.executable("./mvnw") == 1 and "./mvnw" or "mvn"
local build_output = vim.fn.system(mvn_cmd .. " clean compile test-compile")
if vim.v.shell_error == 0 then
  print("✅ Maven build completed successfully")
else
  framework.die("Maven build failed: " .. build_output)
end

-- Setup JDTLS first (required for Java DAP)
local jdtls_config = lsp_setup.make_lsp_config(config, paths.main_file, "main file")
local jdtls_client = lsp_setup.setup_and_wait_for_lsp(jdtls_config)

function test_dap_available()
  -- Verify JDTLS is available (required for Java DAP)
  luaunit.assertNotNil(jdtls_client, "JDTLS client should be available for DAP")
  luaunit.assertEquals(jdtls_client.name, "jdtls", "Should use JDTLS server")

  -- Test DAP availability
  local dap = dap_utils.ensure_dap_available(config.dap.adapter_name)
  luaunit.assertNotNil(dap, "DAP should be available")
end

function test_dap_configurations()
  local config_info = dap_utils.test_dap_configurations("java")
  luaunit.assertNotNil(config_info, "Should return configuration info")
  luaunit.assertTrue(config_info.count > 0, "Should have at least one DAP configuration")
end

function test_debug_dwim_command()
  local debug_files = {
    {
      name = "main_file",
      path = paths.main_file,
      description = "Java program",
      breakpoint_line = 9,
      is_test = false,
    },
    {
      name = "test_file",
      path = paths.test_file,
      description = "Java test file",
      is_test = true,
      breakpoint_line = 11,
    }
  }

  local dwim_results = dap_utils.test_debug_dwim(debug_files)
  luaunit.assertNotNil(dwim_results, "Should return DebugDwim test results")
  luaunit.assertTrue(dwim_results.command_available, "DebugDwim command should be available")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
