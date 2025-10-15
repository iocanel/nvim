-- Run with:
--   nvim --headless "+luafile tests/c/dap.lua"
-- Env overrides (optional):
--   CLANGD_WAIT_MS=15000
--   DAP_WAIT_MS=15000

-- Load utilities
local luaunit = dofile("tests/lib/luaunit.lua")
local framework = dofile("tests/lib/framework.lua")
local lsp_utils = dofile("tests/lib/lsp.lua")
local dap_utils = dofile("tests/lib/dap.lua")
local config = dofile("tests/c/config.lua")

-- Setup test environment
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "hello_world.c",
  test_file = "test_helloworld.c",
  makefile = "Makefile"
}
local paths = framework.setup_project_paths(this_dir, "test_project", required_files)
framework.enter_project_dir(paths.project_root)

-- Build the project if Makefile exists
if vim.fn.filereadable("Makefile") == 1 then
  print("Cleaning and building C project...")
  -- Clean first to remove any pre-existing executables
  local clean_output = vim.fn.system("make clean")
  local make_output = vim.fn.system("make")
  if vim.v.shell_error == 0 then
    print("✅ Make compilation completed successfully")
    -- Debug: Check what executables were created
    local ls_exec = vim.fn.system("ls -la hello_world test_helloworld 2>/dev/null")
    if ls_exec ~= "" then
      print("Built executables found:")
      print(ls_exec)
    end
  else
    framework.die("Make compilation failed: " .. make_output)
  end
end

-- Debug: Print current working directory and check if executables exist
print("Current working directory: " .. vim.fn.getcwd())
print("hello_world exists: " .. (vim.fn.filereadable("hello_world") == 1 and "yes" or "no"))
print("Absolute path would be: " .. vim.fn.getcwd() .. "/hello_world")

-- Test if executable can actually run
print("Testing if executable can run...")
local run_test = vim.fn.system("./hello_world 2>&1")
print("Run test output:")
print(run_test)
print("Exit code: " .. vim.v.shell_error)

-- Check what libraries the executable needs
print("Checking library dependencies...")
local ldd_output = vim.fn.system("ldd hello_world 2>&1")
print("Library dependencies:")
print(ldd_output)

-- Check file type
local file_output = vim.fn.system("file hello_world 2>&1")
print("File type:")
print(file_output)

function test_dap_available()
  -- Should not throw an error
  local dap = dap_utils.ensure_dap_available(config.dap.adapter_name)
  luaunit.assertNotNil(dap, "DAP should be available")
end

function test_dap_configurations()
  local config_info = dap_utils.test_dap_configurations("c")
  luaunit.assertNotNil(config_info, "Should return configuration info")
  luaunit.assertTrue(config_info.count > 0, "Should have at least one DAP configuration")
end

function test_debug_dwim_command()
  local debug_files = {
    {
      name = "main_file",
      path = paths.main_file,
      description = "C program",
      breakpoint_line = 12,
      is_test = false,
    },
    {
      name = "test_file",
      path = paths.test_file,
      description = "C test file",
      is_test = true,
      breakpoint_line = 10,
    }
  }

  local dwim_results = dap_utils.test_debug_dwim(debug_files)
  luaunit.assertNotNil(dwim_results, "Should return DebugDwim test results")
  luaunit.assertTrue(dwim_results.command_available, "DebugDwim command should be available")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
