-- Run with:
--   nvim --headless "+luafile tests/java/lsp.lua"
-- Env overrides (optional):
--   JDTLS_WAIT_MS=25000

-- Load utilities
local luaunit = dofile("tests/lib/luaunit.lua")
local framework = dofile("tests/lib/framework.lua")
local lsp_utils = dofile("tests/lib/lsp.lua")
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

-- Wait for JDTLS to attach and project import to complete
print("Waiting for JDTLS to attach and project import to complete...")
local timeout = framework.get_timeout("JDTLS_WAIT_MS", 50000)
local jdtls_client
vim.cmd.edit(vim.fn.fnameescape(paths.main_file))
framework.validate_filetype("java", "main file")

local attached = vim.wait(timeout, function()
  for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
    if ok and attached_buf and c.initialized then
      -- Wait for JDTLS to have basic capabilities
      local caps = c.server_capabilities or {}
      local has_basic_caps = caps.hoverProvider 
                          or caps.definitionProvider 
                          or caps.textDocumentSync ~= nil
                          or caps.documentSymbolProvider
      if has_basic_caps then
        jdtls_client = c
        return true
      end
    end
  end
  return false
end, 1000)

if attached then
  -- Additional wait to ensure stability after ServiceReady
  vim.wait(3000, function() return false end, 500)
else
  framework.die("JDTLS did not attach within timeout")
end

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
    "main class",
    { pattern = "class App", column_offset = 6 }
  )

  local result = lsp_utils.test_file_lsp(main_config)

  -- Assert that LSP client was returned
  luaunit.assertNotNil(result.client, "LSP client should be attached")
  luaunit.assertEquals(result.client.name, "jdtls", "Should use jdtls server")
  luaunit.assertTrue(#result.available_caps > 0, "Should have available capabilities")
end

function test_service_file_lsp()
  local service_config = make_lsp_config(
    paths.service_file,
    "service class",
    { pattern = "class GreetingService", column_offset = 6 }
  )

  local result = lsp_utils.test_file_lsp(service_config)

  -- Assert that LSP client was returned
  luaunit.assertNotNil(result.client, "LSP client should be attached")
  luaunit.assertEquals(result.client.name, "jdtls", "Should use jdtls server")
  luaunit.assertTrue(#result.available_caps > 0, "Should have available capabilities")
end

function test_test_file_lsp()
  local test_config = make_lsp_config(
    paths.test_file,
    "test class",
    { pattern = "class GreetingServiceTest", column_offset = 6 }
  )

  local result = lsp_utils.test_file_lsp(test_config)

  -- Assert that LSP client was returned
  luaunit.assertNotNil(result.client, "LSP client should be attached")
  luaunit.assertEquals(result.client.name, "jdtls", "Should use jdtls server")
  luaunit.assertTrue(#result.available_caps > 0, "Should have available capabilities")
end

function test_shared_client()
  local files_to_check = {
    { file_path = paths.main_file, description = "main class" },
    { file_path = paths.service_file, description = "service class" },
    { file_path = paths.test_file, description = "test class" }
  }

  lsp_utils.test_shared_client(files_to_check, config.lsp.server_name)

  -- For now, just assert the test completed without error
  luaunit.assertTrue(true, "Shared client test completed")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
