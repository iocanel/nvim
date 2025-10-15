-- Run with:
--   nvim --headless "+luafile tests/go/dap.lua"
-- Env overrides (optional):
--   GOPLS_WAIT_MS=15000
--   DAP_WAIT_MS=20000

-- Load utilities
local luaunit = dofile("tests/lib/luaunit.lua")
local framework = dofile("tests/lib/framework.lua")
local lsp_utils = dofile("tests/lib/lsp.lua")
local dap_utils = dofile("tests/lib/dap.lua")
local config = dofile("tests/go/config.lua")

-- Setup test environment
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "helloworld.go",
  test_file = "helloworld_test.go"
}
local paths = framework.setup_project_paths(this_dir, "test_project", required_files)
framework.enter_project_dir(paths.project_root)

function test_dap_available()
  -- Should not throw an error
  local dap = dap_utils.ensure_dap_available(config.dap.adapter_name)
  luaunit.assertNotNil(dap, "DAP should be available")
  luaunit.assertNotNil(dap.adapters.go, "Go DAP adapter should be configured")
end

function test_dap_configurations()
  local config_info = dap_utils.test_dap_configurations("go")
  luaunit.assertNotNil(config_info, "Should return configuration info")
  luaunit.assertTrue(config_info.count > 0, "Should have at least one DAP configuration")
end

function test_debug_dwim_command()
  local debug_files = {
    {
      name = "main_file",
      path = paths.main_file,
      description = "Go program",
      breakpoint_line = 9,
      is_test = false,
    },
    {
      name = "test_file",
      path = paths.test_file,
      description = "Go test file",
      is_test = true,
      breakpoint_line = 8,
    }
  }

  local dwim_results = dap_utils.test_debug_dwim(debug_files)
  luaunit.assertNotNil(dwim_results, "Should return DebugDwim test results")
  luaunit.assertTrue(dwim_results.command_available, "DebugDwim command should be available")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
