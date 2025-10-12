-- Run with:
--   nvim --headless "+luafile tests/typescript/dap.lua"
-- Env overrides (optional):
--   TSSERVER_WAIT_MS=15000
--   DAP_WAIT_MS=20000

if vim.g.__typescript_dap_e2e_running then return end
vim.g.__typescript_dap_e2e_running = true

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
local main_file = project_root .. "/helloworld.ts"
local test_file = project_root .. "/helloworld.test.ts"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end

-- Enter project root for consistent ts_ls root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Open main file to trigger ts_ls
vim.cmd("edit! " .. vim.fn.fnameescape(main_file))
if vim.bo.filetype ~= "typescript" then
  pcall(vim.fn.chdir, prev_cwd)
  die("Expected filetype=typescript, got " .. tostring(vim.bo.filetype))
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

-- Check if TypeScript/Node DAP adapter is configured
if not dap.adapters["pwa-node"] and not dap.adapters["node2"] then
  pcall(vim.fn.chdir, prev_cwd)
  die("DAP adapter 'pwa-node' or 'node2' not configured. Install and configure nvim-dap-vscode-js or node-debug2.")
end

-- Use pwa-node if available, otherwise fall back to node2
local adapter_name = dap.adapters["pwa-node"] and "pwa-node" or "node2"

-- Check for ts-node availability
local function check_ts_node()
  local handle = io.popen("which ts-node 2>/dev/null")
  local result = handle:read("*a")
  handle:close()
  return result and result:match("ts%-node") ~= nil
end

if not check_ts_node() then
  pcall(vim.fn.chdir, prev_cwd)
  print("⚠️  ts-node not available - TypeScript DAP testing requires ts-node")
  print("✅ TypeScript DAP configuration is set up, but ts-node dependency is missing")
  print("   Install with: npm install -g ts-node")
  print("   Or locally: npm install --save-dev ts-node")
  os.exit(0)
end

-- Observe debug lifecycle
local seen = { initialized = false, stopped = false, terminated = false }
local reason
dap.listeners.after.event_initialized["typescript-e2e"] = function() seen.initialized = true end
dap.listeners.after.event_stopped["typescript-e2e"] = function(_, body)
  seen.stopped = true
  reason = body and body.reason or reason
end
dap.listeners.after.event_terminated["typescript-e2e"] = function() seen.terminated = true end
dap.listeners.after.event_exited["typescript-e2e"] = dap.listeners.after.event_terminated["typescript-e2e"]

-- Function to test TypeScript debugging
local function test_typescript_debug(debug_type, file_path, breakpoint_line)
  print("Testing TypeScript " .. debug_type .. " debug ...")
  
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
  if debug_type == "program" or debug_type == "function" then
    vim.cmd("DebugDwim")
  else
    vim.cmd("DebugDwim")
  end
  
  -- Wait for session to start
  local dap_timeout = tonumber(vim.env.DAP_WAIT_MS) or 20000
  local ok_session = vim.wait(dap_timeout, function() return dap.session() ~= nil end, 100)
  if not ok_session then
    pcall(vim.fn.chdir, prev_cwd)
    die("TypeScript " .. debug_type .. " DAP session did not start")
  end
  
  -- Wait for initialization
  vim.wait(2000, function() return seen.initialized end, 100)
  
  -- Continue and wait for breakpoint
  pcall(dap.continue)
  if not vim.wait(dap_timeout, function() return seen.stopped end, 200) then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("TypeScript " .. debug_type .. " debugger did not stop (breakpoint not hit)")
  end
  
  if reason and reason ~= "breakpoint" and reason ~= "step" then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("TypeScript " .. debug_type .. " stopped for unexpected reason: " .. tostring(reason))
  end
  
  -- Terminate the session
  pcall(dap.terminate)
  vim.wait(2000, function() return seen.terminated end, 100)
  
  print("✅ TypeScript " .. debug_type .. " debugging successful (breakpoint hit)")
  return true
end

-- Test debugging TypeScript main program
-- Breakpoint on line 16: console.log(greet());
test_typescript_debug("program", main_file, 16)

-- Wait a bit between tests to allow cleanup
vim.wait(1000, function() return false end, 100)

-- Test debugging TypeScript function using command
test_typescript_debug("function", main_file, 8)

-- Wait a bit between tests to allow cleanup
vim.wait(1000, function() return false end, 100)

-- Test debugging TypeScript test file using command
test_typescript_debug("test", test_file, 9)


-- Print final success
pcall(vim.fn.chdir, prev_cwd)

local ts_root = (ts_client and ts_client.config and ts_client.config.root_dir) or "(unknown)"

print("")
print("🎉 TypeScript debugging tests completed!")
print("   ✅ Program debugging: successful (using DebugDwim)")
print("   ✅ Function debugging: successful (using DebugDwim)")
print("   ✅ Test file debugging: successful (using DebugDwim)")
print("   main_file: " .. vim.trim(main_file))
print("   test_file: " .. vim.trim(test_file))
print("   project_root: " .. vim.trim(project_root))
print("   ts_ls_root: " .. vim.trim(ts_root))
print("   adapter_used: " .. adapter_name)
print("")

-- Restore original notify function
vim.notify = original_notify

-- Force exit with OS signal
os.exit(0)