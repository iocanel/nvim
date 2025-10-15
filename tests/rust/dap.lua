-- Run with:
--   nvim --headless "+luafile tests/rust/dap.lua"
-- Env overrides (optional):
--   RUST_ANALYZER_WAIT_MS=20000
--   DAP_WAIT_MS=20000

-- Load utilities
local luaunit = dofile("tests/lib/luaunit.lua")
local framework = dofile("tests/lib/framework.lua")
local lsp_utils = dofile("tests/lib/lsp.lua")
local dap_utils = dofile("tests/lib/dap.lua")
local config = dofile("tests/rust/config.lua")

-- Setup test environment
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "src/main.rs",
  cargo_file = "Cargo.toml",
}
local paths = framework.setup_project_paths(this_dir, "test_project", required_files)
framework.enter_project_dir(paths.project_root)

-- Build the project using Cargo (required for debugging)
print("Building Rust project...")
local build_output = vim.fn.system("cargo build")
if vim.v.shell_error == 0 then
  print("✅ Cargo build completed successfully")
else
  framework.die("Cargo build failed: " .. build_output)
end

-- Build test executables (required for test debugging)
print("Building Rust test executables...")
local test_build_output = vim.fn.system("cargo test --no-run")
if vim.v.shell_error == 0 then
  print("✅ Cargo test build completed successfully")
else
  framework.die("Cargo test build failed: " .. test_build_output)
end

function test_dap_available()
  -- Should not throw an error
  local dap = dap_utils.ensure_dap_available(config.dap.adapter_name)
  luaunit.assertNotNil(dap, "DAP should be available")
end

function test_dap_configurations()
  local config_info = dap_utils.test_dap_configurations("rust")
  luaunit.assertNotNil(config_info, "Should return configuration info")
  luaunit.assertTrue(config_info.count > 0, "Should have at least one DAP configuration")
end

function test_debug_dwim_command()
  local debug_files = {
    {
      name = "main_file",
      path = paths.main_file,
      description = "Rust program",
      breakpoint_line = 8,
      is_test = false,
    },
    {
      name = "main_file",
      path = paths.main_file,
      description = "Rust inline test",
      breakpoint_line = 18,
      is_test = true,
    },
  }

  local dwim_results = dap_utils.test_debug_dwim(debug_files)
  luaunit.assertNotNil(dwim_results, "Should return DebugDwim test results")
  luaunit.assertTrue(dwim_results.command_available, "DebugDwim command should be available")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
