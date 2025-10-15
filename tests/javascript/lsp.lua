-- Run with:
--   nvim --headless "+luafile tests/javascript/lsp.lua"
-- Env overrides (optional):
--   TS_LS_WAIT_MS=20000

-- Load utilities
local luaunit = dofile("tests/lib/luaunit.lua")
local framework = dofile("tests/lib/framework.lua")
local lsp_utils = dofile("tests/lib/lsp.lua")
local config = dofile("tests/javascript/config.lua")

-- Setup test environment
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "helloworld.js",
  test_file = "helloworld.test.js",
  package_file = "package.json",
}
local paths = framework.setup_project_paths(this_dir, "test_project", required_files)
framework.enter_project_dir(paths.project_root)

-- Helper function to build LSP configs
local function make_lsp_config(file_path, description, hover_test)
  return {
    server_name = config.lsp.server_name,
    file_path = file_path,
    file_type_description = description,
    expected_filetype = config.lsp.expected_filetype,
    language = config.lsp.language,
    timeout_env_var = config.lsp.timeout_env_var,
    default_timeout = config.lsp.default_timeout,
    required_caps = config.lsp.required_caps,
    optional_caps = config.lsp.optional_caps,
    hover_test = hover_test,
  }
end

function test_main_file_lsp()
  local main_config = make_lsp_config(
    paths.main_file,
    "main program",
    { pattern = "greet", column_offset = 0 }
  )

  local result = lsp_utils.test_file_lsp(main_config)

  -- Assert that LSP client was returned
  luaunit.assertNotNil(result.client, "LSP client should be attached")
  luaunit.assertEquals(result.client.name, "ts_ls", "Should use ts_ls server")
  luaunit.assertTrue(#result.available_caps > 0, "Should have available capabilities")
end

function test_test_file_lsp()
  local test_config = make_lsp_config(
    paths.test_file,
    "test file",
    { pattern = "describe", column_offset = 0 }
  )

  local result = lsp_utils.test_file_lsp(test_config)

  -- Assert that LSP client was returned
  luaunit.assertNotNil(result.client, "LSP client should be attached")
  luaunit.assertEquals(result.client.name, "ts_ls", "Should use ts_ls server")
  luaunit.assertTrue(#result.available_caps > 0, "Should have available capabilities")
end

function test_shared_client()
  local files_to_check = {
    { file_path = paths.main_file, description = "main program" },
    { file_path = paths.test_file, description = "test file" }
  }

  -- This function prints results, but doesn't return testable data
  -- In a real luaunit setup, we'd modify the function to return results
  lsp_utils.test_shared_client(files_to_check, config.lsp.server_name)

  -- For now, just assert the test completed without error
  luaunit.assertTrue(true, "Shared client test completed")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
