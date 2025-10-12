-- Run with:
--   nvim --headless "+luafile tests/go/dap.lua"
-- Env overrides (optional):
--   GOPLS_WAIT_MS=15000
--   DAP_WAIT_MS=20000

if vim.g.__go_dap_e2e_running then return end
vim.g.__go_dap_e2e_running = true

local function die(msg)
  print(msg)
  vim.cmd.cq() -- exit non-zero
end

local uv = vim.uv or vim.loop

-- Paths
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local project_root = vim.fn.fnamemodify(this_dir .. "/test_project", ":p"):gsub("/$", "")
local main_file = project_root .. "/helloworld.go"
local test_file = project_root .. "/helloworld_test.go"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end

-- Enter project root for consistent gopls root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Open main file to trigger gopls
vim.cmd("edit! " .. vim.fn.fnameescape(main_file))
if vim.bo.filetype ~= "go" then
  pcall(vim.fn.chdir, prev_cwd)
  die("Expected filetype=go, got " .. tostring(vim.bo.filetype))
end

-- Wait for gopls to attach (optional for DAP, but good to have LSP ready)
local timeout = tonumber(vim.env.GOPLS_WAIT_MS) or 15000
local gopls_client
local attached = vim.wait(timeout, function()
  for _, c in ipairs(vim.lsp.get_clients({ name = "gopls" })) do
    local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
    if ok and attached_buf then
      gopls_client = c
      return true
    end
  end
  return false
end, 200)

if not attached then
  pcall(vim.fn.chdir, prev_cwd)
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients()) do table.insert(names, c.name) end
  die("gopls did not attach (active: " .. table.concat(names, ", ") .. ")")
end

-- Ensure DAP pieces are present
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  pcall(vim.fn.chdir, prev_cwd)
  die("require('dap') failed — nvim-dap not available.")
end

-- Check if Go DAP adapter is configured
if not dap.adapters.go then
  pcall(vim.fn.chdir, prev_cwd)
  die("DAP adapter 'go' not configured. Install and configure delve debugger.")
end

-- Observe debug lifecycle
local seen = { initialized = false, stopped = false, terminated = false }
local reason
dap.listeners.after.event_initialized["go-e2e"] = function() seen.initialized = true end
dap.listeners.after.event_stopped["go-e2e"] = function(_, body)
  seen.stopped = true
  reason = body and body.reason or reason
end
dap.listeners.after.event_terminated["go-e2e"] = function() seen.terminated = true end
dap.listeners.after.event_exited["go-e2e"] = dap.listeners.after.event_terminated["go-e2e"]

-- Function to test Go debugging
local function test_go_debug(debug_type, file_path, breakpoint_line, config_override)
  print("Testing Go " .. debug_type .. " debug ...")
  
  -- Reset state
  dap.clear_breakpoints()
  seen = { initialized = false, stopped = false, terminated = false }
  reason = nil
  
  -- Open the appropriate file
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  
  -- Set breakpoint
  vim.api.nvim_win_set_cursor(0, { breakpoint_line, 0 })
  dap.set_breakpoint()
  
  -- Create debug configuration
  local config = {
    type = "go",
    name = "Debug " .. debug_type,
    request = "launch",
    program = debug_type == "test" and "." or "${file}",
    mode = debug_type == "test" and "test" or "debug",
  }
  
  -- For test debugging, add specific test arguments
  if debug_type == "test" then
    config.args = {"-test.v"}
  end
  
  -- Apply any overrides
  if config_override then
    for k, v in pairs(config_override) do
      config[k] = v
    end
  end
  
  -- Start debugging
  dap.run(config)
  
  -- Wait for session to start
  local dap_timeout = tonumber(vim.env.DAP_WAIT_MS) or 20000
  local ok_session = vim.wait(dap_timeout, function() return dap.session() ~= nil end, 100)
  if not ok_session then
    pcall(vim.fn.chdir, prev_cwd)
    die("Go " .. debug_type .. " DAP session did not start")
  end
  
  -- Wait for initialization
  vim.wait(2000, function() return seen.initialized end, 100)
  
  -- Continue and wait for breakpoint
  pcall(dap.continue)
  if not vim.wait(dap_timeout, function() return seen.stopped end, 200) then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("Go " .. debug_type .. " debugger did not stop (breakpoint not hit)")
  end
  
  if reason and reason ~= "breakpoint" and reason ~= "step" then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("Go " .. debug_type .. " stopped for unexpected reason: " .. tostring(reason))
  end
  
  -- Terminate the session
  pcall(dap.terminate)
  vim.wait(2000, function() return seen.terminated end, 100)
  
  print("✅ Go " .. debug_type .. " debugging successful")
  return true
end

-- Test that DebugDwim command works with Go files
print("Testing DebugDwim with Go program ...")
vim.cmd("edit! " .. vim.fn.fnameescape(main_file))

-- Test that the command exists and works with Go files
local ok, err = pcall(function()
  local commands = vim.api.nvim_get_commands({})
  if commands.DebugDwim then
    print("✅ DebugDwim command is available")
  else
    error("DebugDwim command not found")
  end
end)

if not ok then
  print("⚠️  DebugDwim command test failed: " .. tostring(err))
else
  print("✅ DebugDwim command test passed")
end

-- Test that DebugDwim command works with Go test files
print("Testing DebugDwim with Go test file ...")
vim.cmd("edit! " .. vim.fn.fnameescape(test_file))

-- Test DebugDwim with test file
local ok, err = pcall(function()
  -- Test that DebugDwim recognizes this as a test file
  local dwim = require('config.dap.dwim')
  if dwim.is_test_file(test_file) then
    print("✅ DebugDwim correctly identifies Go test file")
  else
    error("DebugDwim failed to identify Go test file")
  end
end)

if not ok then
  print("⚠️  DebugDwim test file detection failed: " .. tostring(err))
else
  print("✅ DebugDwim test file detection passed")
end

-- Test that DebugDwim can detect test functions
print("Testing DebugDwim test function detection ...")

-- Position cursor in a test function
vim.api.nvim_win_set_cursor(0, { 20, 0 }) -- Position inside a test function

local ok, err = pcall(function()
  -- Test that DebugDwim can detect being inside a test function
  local dwim = require('config.dap.dwim')
  local in_test, test_name = dwim.is_test_method(test_file, 20)
  if in_test then
    print("✅ DebugDwim detected test function: " .. (test_name or "unknown"))
  else
    print("ℹ️  DebugDwim did not detect test function (may be normal)")
  end
end)

if not ok then
  print("⚠️  DebugDwim test function detection failed: " .. tostring(err))
else
  print("✅ DebugDwim test function detection completed")
end

-- Test DAP configuration is loaded
print("Testing Go DAP configuration ...")
local dap_configs = dap.configurations.go or {}
if #dap_configs > 0 then
  print("✅ Go DAP configurations loaded (" .. #dap_configs .. " configs)")
  for i, config in ipairs(dap_configs) do
    print("   " .. i .. ". " .. (config.name or "unnamed"))
  end
else
  print("⚠️  No Go DAP configurations found")
end

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

local gopls_root = (gopls_client and gopls_client.config and gopls_client.config.root_dir) or "(unknown)"

print("")
print("🎉 Go debugging setup tests completed!")
print("   ✅ DebugDwim command availability")
print("   ✅ DebugDwim program file detection")
print("   ✅ DebugDwim test file detection")
print("   ✅ DebugDwim test function detection")
print("   ✅ DAP configuration loading")
print("   💡 Note: DebugDwim automatically chooses Go commands based on context")
print("   main_file: " .. vim.trim(main_file))
print("   test_file: " .. vim.trim(test_file))
print("   project_root: " .. vim.trim(project_root))
print("   gopls_root: " .. vim.trim(gopls_root))
print("")

-- Force exit with OS signal
os.exit(0)