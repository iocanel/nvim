-- Run with:
--   nvim --headless "+luafile tests/java/dap.lua"
-- Env overrides (optional):
--   JDTLS_WAIT_MS=30000
--   DAP_WAIT_MS=25000

-- Load utilities
local luaunit = dofile("tests/lib/luaunit.lua")
local framework = dofile("tests/lib/framework.lua")
local dap_utils = dofile("tests/lib/dap.lua")
local config = dofile("tests/java/config.lua")

-- Setup test environment
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "src/main/java/com/iocanel/App.java",
  service_file = "src/main/java/com/iocanel/GreetingService.java",
  test_file = "src/test/java/com/iocanel/GreetingServiceTest.java"
}
local paths = framework.setup_project_paths(this_dir, "test_project", required_files)
framework.enter_project_dir(paths.project_root)

-- Wait for JDTLS to attach and project import to complete
vim.cmd.edit(vim.fn.fnameescape(paths.main_file))
framework.validate_filetype("java", "main file")

print("Waiting for JDTLS to attach and project import to complete...")
local timeout = framework.get_timeout("JDTLS_WAIT_MS", 30000)
local jdtls_client
local attached = vim.wait(timeout, function()
  for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
    if ok and attached_buf and c.initialized then
      jdtls_client = c
      return true
    end
  end
  return false
end, 500)

if attached then
  vim.wait(10000, function() return false end, 1000) -- Wait for project import
else
  framework.die("JDTLS did not attach within timeout")
end

function test_dap_available()
  local dap = dap_utils.ensure_dap_available(config.dap.adapter_name)
  luaunit.assertNotNil(dap, "DAP should be available")
  
  -- Check if JDTLS extension is available
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  luaunit.assertTrue(ok_jdtls, "nvim-jdtls should be available")
  
  -- Setup DAP adapter for Java
  if ok_jdtls then
    pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
  end
end

function test_debug_dwim_command()
  -- Test that DebugDwim command exists
  local commands = vim.api.nvim_get_commands({})
  luaunit.assertTrue(commands.DebugDwim ~= nil, "DebugDwim command should be available")
end

function test_jdtls_client()
  -- Test that JDTLS client is properly attached
  luaunit.assertNotNil(jdtls_client, "JDTLS client should be attached")
  luaunit.assertEquals(jdtls_client.name, "jdtls", "Should use jdtls server")
  luaunit.assertTrue(jdtls_client.initialized, "JDTLS should be initialized")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
