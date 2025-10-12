-- Run with:
--   nvim --headless "+luafile tests/dap_java.lua"
-- Env overrides (optional):
--   JDTLS_WAIT_MS=20000

if vim.g.__java_dap_e2e_running then return end
vim.g.__java_dap_e2e_running = true

local function die(msg)
  print(msg)
  vim.cmd.cq() -- exit non-zero
end

local uv = vim.uv or vim.loop

-- Paths
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local project_root = vim.fn.fnamemodify(this_dir .. "/test_project", ":p"):gsub("/$", "")
local main_file = project_root .. "/src/main/java/com/iocanel/App.java"
local test_file = project_root .. "/src/test/java/com/iocanel/AppTest.java"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end

-- Enter project root for consistent jdtls root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Open main file to trigger jdtls
vim.cmd.edit(vim.fn.fnameescape(main_file))
if vim.bo.filetype ~= "java" then
  pcall(vim.fn.chdir, prev_cwd)
  die("Expected filetype=java, got " .. tostring(vim.bo.filetype))
end

-- Wait for jdtls to attach
local timeout = tonumber(vim.env.JDTLS_WAIT_MS) or 15000
local jdtls_client
local attached = vim.wait(timeout, function()
  for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
    if ok and attached_buf and (c.initialized or c.server_capabilities) then
      jdtls_client = c
      return true
    end
  end
  return false
end, 200)

if not attached then
  pcall(vim.fn.chdir, prev_cwd)
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients()) do table.insert(names, c.name) end
  die("jdtls did not attach (active: " .. table.concat(names, ", ") .. ")")
end

-- Ensure DAP pieces are present
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  pcall(vim.fn.chdir, prev_cwd)
  die("require('dap') failed — nvim-dap not available.")
end

local ok_jdtls, jdtls = pcall(require, "jdtls")
if not ok_jdtls then
  pcall(vim.fn.chdir, prev_cwd)
  die("require('jdtls') failed — nvim-jdtls not available.")
end

-- In CI/headless, compile first so DebugDwim has something to run
pcall(function() jdtls.compile("full") end)

-- Prepare breakpoint on line 9 (cursor-based API)
dap.clear_breakpoints()
vim.api.nvim_win_set_cursor(0, { 9, 0 })
dap.set_breakpoint()

-- Observe lifecycle; also poll for a real session as a fallback
local seen = { initialized = false, stopped = false, terminated = false }
local reason
dap.listeners.after.event_initialized["java-e2e"] = function() seen.initialized = true end
dap.listeners.after.event_stopped["java-e2e"] = function(_, body)
  seen.stopped = true
  reason = body and body.reason or reason
end
dap.listeners.after.event_terminated["java-e2e"] = function() seen.terminated = true end
dap.listeners.after.event_exited["java-e2e"] = dap.listeners.after.event_terminated["java-e2e"]

-- Make sure adapter is registered (some configs defer setup)
pcall(jdtls.setup_dap, { hotcodereplace = "auto" })

-- If nvim-jdtls' picker would prompt in TUI, force it to pick the only main class non-interactively
if jdtls.pick_one_async then
  local orig = jdtls.pick_one_async
  jdtls.pick_one_async = function(items, prompt, label_fn, cb)
    -- auto-pick the first/only item to avoid UI in headless
    return cb(items[1])
  end
  -- restore after launch
  vim.defer_fn(function() jdtls.pick_one_async = orig end, 1000)
end

-- Function to test a debug command
local function test_debug_command(command_name, file_path, breakpoint_line)
  print("Testing " .. command_name .. " ...")
  
  -- Reset state
  dap.clear_breakpoints()
  seen = { initialized = false, stopped = false, terminated = false }
  reason = nil
  
  -- Open the appropriate file (force without saving)
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  
  -- Set breakpoint
  vim.api.nvim_win_set_cursor(0, { breakpoint_line, 0 })
  dap.set_breakpoint()
  
  -- Execute the command
  local ok_cmd, err = pcall(vim.cmd, command_name)
  if not ok_cmd then
    pcall(vim.fn.chdir, prev_cwd)
    local adapter = require("dap").adapters and require("dap").adapters.java
    die(command_name .. " failed: " .. tostring(err) ..
        (adapter and "" or " (dap.adapters.java is not registered)"))
  end
  
  -- Wait for session to start
  local ok_session = vim.wait(20000, function() return dap.session() ~= nil end, 100)
  if not ok_session then
    pcall(vim.fn.chdir, prev_cwd)
    local adapter = require("dap").adapters and require("dap").adapters.java
    die("DAP session did not start for " .. command_name .. ". " ..
        "adapters.java present: " .. tostring(adapter ~= nil))
  end
  
  -- Wait for initialization
  vim.wait(2000, function() return seen.initialized end, 100)
  
  -- Continue and wait for breakpoint
  pcall(dap.continue)
  if not vim.wait(20000, function() return seen.stopped end, 200) then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die(command_name .. " debugger did not stop (breakpoint not hit)")
  end
  
  if reason and reason ~= "breakpoint" and reason ~= "step" then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die(command_name .. " stopped for unexpected reason: " .. tostring(reason))
  end
  
  -- Terminate the session
  pcall(dap.terminate)
  vim.wait(2000, function() return seen.terminated end, 100)
  
  print("✅ " .. command_name .. " launched and hit breakpoint successfully")
  return true
end

-- Test DebugDwim
test_debug_command("DebugDwim", main_file, 9)

-- Test DebugDwim
test_debug_command("DebugDwim", test_file, 11)

-- Test DebugDwim (cursor should be on the test method)
vim.cmd("edit! " .. vim.fn.fnameescape(test_file))
vim.api.nvim_win_set_cursor(0, { 10, 0 }) -- Position cursor on @Test annotation
test_debug_command("DebugDwim", test_file, 11)

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

local jdtls_root = (jdtls_client.config and jdtls_client.config.root_dir) or "(unknown)"

print("🎉 All debug commands tested successfully!")
print("   Command tested: DebugDwim (auto-detects context)")
print("   main_file: " .. vim.trim(main_file))
print("   test_file: " .. vim.trim(test_file))
print("   project_root: " .. vim.trim(project_root))
print("")

-- Force exit with OS signal - most aggressive approach
os.exit(0)
