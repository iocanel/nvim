-- Run with:
--   nvim --headless "+luafile tests/javascript/dap.lua"
-- Env overrides (optional):
--   TSSERVER_WAIT_MS=15000
--   DAP_WAIT_MS=20000

if vim.g.__javascript_dap_e2e_running then return end
vim.g.__javascript_dap_e2e_running = true

-- Suppress DAP error messages for cleaner test output
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  -- Suppress common DAP disconnection errors
  if type(msg) == "string" and (
    msg:match("Error retrieving stack traces") or
    msg:match("Error setting breakpoints") or
    msg:match("Server.*disconnected unexpectedly") or
    msg:match("Session terminated")
  ) then
    return
  end
  return original_notify(msg, level, opts)
end

local function die(msg)
  print(msg)
  vim.cmd.cq() -- exit non-zero
end

local uv = vim.uv or vim.loop

-- Paths
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local project_root = vim.fn.fnamemodify(this_dir .. "/test_project", ":p"):gsub("/$", "")
local main_file = project_root .. "/helloworld.js"
local test_file = project_root .. "/helloworld.test.js"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end

-- Enter project root for consistent ts_ls root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Open main file to trigger ts_ls
vim.cmd("edit! " .. vim.fn.fnameescape(main_file))
if vim.bo.filetype ~= "javascript" then
  pcall(vim.fn.chdir, prev_cwd)
  die("Expected filetype=javascript, got " .. tostring(vim.bo.filetype))
end

-- Wait for ts_ls to attach (optional for DAP, but good to have LSP ready)
local timeout = tonumber(vim.env.TSSERVER_WAIT_MS) or 15000
local ts_client
local attached = vim.wait(timeout, function()
  for _, c in ipairs(vim.lsp.get_clients({ name = "ts_ls" })) do
    local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
    if ok and attached_buf then
      ts_client = c
      return true
    end
  end
  return false
end, 200)

if not attached then
  pcall(vim.fn.chdir, prev_cwd)
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients()) do table.insert(names, c.name) end
  die("ts_ls did not attach (active: " .. table.concat(names, ", ") .. ")")
end

-- Ensure DAP pieces are present
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  pcall(vim.fn.chdir, prev_cwd)
  die("require('dap') failed — nvim-dap not available.")
end

-- Check if JavaScript/Node DAP adapter is configured
if not dap.adapters["pwa-node"] then
  pcall(vim.fn.chdir, prev_cwd)
  die("DAP adapter 'pwa-node' not configured. Install and configure nvim-dap-vscode-js.")
end

-- Observe debug lifecycle
local seen = { initialized = false, stopped = false, terminated = false }
local reason
dap.listeners.after.event_initialized["javascript-e2e"] = function() seen.initialized = true end
dap.listeners.after.event_stopped["javascript-e2e"] = function(_, body)
  seen.stopped = true
  reason = body and body.reason or reason
end
dap.listeners.after.event_terminated["javascript-e2e"] = function() seen.terminated = true end
dap.listeners.after.event_exited["javascript-e2e"] = dap.listeners.after.event_terminated["javascript-e2e"]

-- Function to test JavaScript debugging
local function test_javascript_debug(debug_type, file_path, breakpoint_line)
  print("Testing JavaScript " .. debug_type .. " debug ...")

  -- Reset state
  dap.clear_breakpoints()
  seen = { initialized = false, stopped = false, terminated = false }
  reason = nil

  -- Open the appropriate file
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))

  -- Set breakpoint
  vim.api.nvim_win_set_cursor(0, { breakpoint_line, 0 })
  dap.set_breakpoint()

  -- Use the appropriate debug command instead of hardcoded config
  if debug_type == "program" then
    vim.cmd("JavascriptDebugFile")
  else
    vim.cmd("JavascriptDebugTestFile")
  end

  -- Wait for session to start
  local dap_timeout = tonumber(vim.env.DAP_WAIT_MS) or 20000
  local ok_session = vim.wait(dap_timeout, function() return dap.session() ~= nil end, 100)
  if not ok_session then
    pcall(vim.fn.chdir, prev_cwd)
    die("JavaScript " .. debug_type .. " DAP session did not start")
  end

  -- Wait for initialization
  vim.wait(2000, function() return seen.initialized end, 100)

  -- Continue and wait for breakpoint
  pcall(dap.continue)
  if not vim.wait(dap_timeout, function() return seen.stopped end, 200) then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("JavaScript " .. debug_type .. " debugger did not stop (breakpoint not hit)")
  end

  if reason and reason ~= "breakpoint" and reason ~= "step" then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("JavaScript " .. debug_type .. " stopped for unexpected reason: " .. tostring(reason))
  end
  
  -- Terminate the session
  pcall(dap.terminate)
  vim.wait(2000, function() return seen.terminated end, 100)
  
  print("✅ JavaScript " .. debug_type .. " debugging successful (breakpoint hit)")
  return true
end

-- Test debugging JavaScript main program
-- Breakpoint on line 34: console.log(greet());
test_javascript_debug("program", main_file, 34)

-- Wait a bit between tests to allow cleanup
vim.wait(1000, function() return false end, 100)

-- Test debugging JavaScript using test file with proper test command
print("Testing JavaScript test file debug ...")
dap.clear_breakpoints()
seen = { initialized = false, stopped = false, terminated = false }
reason = nil

vim.cmd("edit! " .. vim.fn.fnameescape(test_file))
vim.api.nvim_win_set_cursor(0, { 9, 0 }) -- Position on expect statement
dap.set_breakpoint()

-- Use JavascriptDebugTestFile command
vim.cmd("JavascriptDebugTestFile")

-- Wait for session to start
local dap_timeout = tonumber(vim.env.DAP_WAIT_MS) or 20000
local ok_session = vim.wait(dap_timeout, function() return dap.session() ~= nil end, 100)
if not ok_session then
  pcall(vim.fn.chdir, prev_cwd)
  die("JavaScript test file DAP session did not start")
end

-- Wait for initialization
vim.wait(2000, function() return seen.initialized end, 100)

-- Continue and wait for breakpoint
pcall(dap.continue)
if not vim.wait(dap_timeout, function() return seen.stopped end, 200) then
  pcall(dap.terminate)
  pcall(vim.fn.chdir, prev_cwd)
  die("JavaScript test file debugger did not stop (breakpoint not hit)")
end

if reason and reason ~= "breakpoint" and reason ~= "step" then
  pcall(dap.terminate)
  pcall(vim.fn.chdir, prev_cwd)
  die("JavaScript test file stopped for unexpected reason: " .. tostring(reason))
end

-- Terminate the session
pcall(dap.terminate)
vim.wait(2000, function() return seen.terminated end, 100)

print("✅ JavaScript test file debugging successful (breakpoint hit)")

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

local ts_root = (ts_client and ts_client.config and ts_client.config.root_dir) or "(unknown)"

print("")
print("🎉 JavaScript debugging tests completed!")
print("   ✅ Program debugging: successful (using JavascriptDebugFile)")
print("   ✅ Test file debugging: successful (using JavascriptDebugTestFile)")
print("   main_file: " .. vim.trim(main_file))
print("   test_file: " .. vim.trim(test_file))
print("   project_root: " .. vim.trim(project_root))
print("   ts_ls_root: " .. vim.trim(ts_root))
print("")

-- Restore original notify function
vim.notify = original_notify

-- Force exit with OS signal
os.exit(0)
