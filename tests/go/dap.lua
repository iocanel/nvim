-- Run with:
--   nvim --headless "+luafile tests/go/dap.lua"
-- Env overrides (optional):
--   GOPLS_WAIT_MS=15000
--   DAP_WAIT_MS=20000

-- Load utilities
local framework = dofile("tests/lib/framework.lua")
local lsp_utils = dofile("tests/lib/lsp.lua")
local dap_utils = dofile("tests/lib/dap.lua")
local config = dofile("tests/go/config.lua")

if not framework.ensure_single_run('__go_dap_e2e_running') then return end

-- Setup project paths
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "helloworld.go",
  test_file = "helloworld_test.go"
}
local paths = framework.setup_project_paths(this_dir, "test_project", required_files)

-- Enter project directory
local restore_cwd = framework.enter_project_dir(paths.project_root)

-- Open main file and verify LSP attachment (optional for DAP, but good to have)
vim.cmd("edit! " .. vim.fn.fnameescape(paths.main_file))
framework.validate_filetype("go", "main file", restore_cwd)

-- Wait for gopls to attach
local gopls_client = lsp_utils.wait_for_client_attachment(
  config.lsp.server_name,
  framework.get_timeout(config.lsp.timeout_env_var, config.lsp.default_timeout),
  "main file",
  restore_cwd
)

-- Ensure DAP is available and configured
local dap = dap_utils.ensure_dap_available(config.dap.adapter_name, restore_cwd)

-- Setup debug event listeners
local debug_state = dap_utils.setup_debug_listeners("go-e2e")


-- Test DebugDwim functionality
local dwim_files = {
  {
    name = "main_file",
    path = paths.main_file,
    description = "Go program",
    is_test = false,
  },
  {
    name = "test_file", 
    path = paths.test_file,
    description = "Go test file",
    is_test = true,
    test_cursor_line = 20,
  }
}

local dwim_results = dap_utils.test_debug_dwim(dwim_files)

-- Test DAP configurations
local config_info = dap_utils.test_dap_configurations("go")

-- Print final results and cleanup
restore_cwd()

local gopls_root = (gopls_client and gopls_client.config and gopls_client.config.root_dir) or "(unknown)"

print("")
print("🎉 Go debugging setup tests completed!")
print("   ✅ DebugDwim command availability")
print("   ✅ DebugDwim program file detection") 
print("   ✅ DebugDwim test file detection")
print("   ✅ DebugDwim test function detection")
print("   ✅ DAP configuration loading")
print("   💡 Note: DebugDwim automatically chooses Go commands based on context")
print("   main_file: " .. vim.trim(paths.main_file))
print("   test_file: " .. vim.trim(paths.test_file))
print("   project_root: " .. vim.trim(paths.project_root))
print("   gopls_root: " .. vim.trim(gopls_root))
print("")

framework.exit_success()