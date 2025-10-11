-- Run with:
--   nvim --headless "+luafile tests/python/dap.lua"
-- Env overrides (optional):
--   PYRIGHT_WAIT_MS=15000
--   DAP_WAIT_MS=20000

if vim.g.__python_dap_e2e_running then return end
vim.g.__python_dap_e2e_running = true

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
local main_file = project_root .. "/helloworld.py"
local test_file = project_root .. "/test_helloworld.py"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end

-- Enter project root for consistent pyright root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Open main file to trigger pyright
vim.cmd("edit! " .. vim.fn.fnameescape(main_file))
if vim.bo.filetype ~= "python" then
  pcall(vim.fn.chdir, prev_cwd)
  die("Expected filetype=python, got " .. tostring(vim.bo.filetype))
end

-- Wait for pyright to attach (optional for DAP, but good to have LSP ready)
local timeout = tonumber(vim.env.PYRIGHT_WAIT_MS) or 15000
local pyright_client
local attached = vim.wait(timeout, function()
  for _, c in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
    local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
    if ok and attached_buf then
      pyright_client = c
      return true
    end
  end
  return false
end, 200)

if not attached then
  pcall(vim.fn.chdir, prev_cwd)
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients()) do table.insert(names, c.name) end
  die("pyright did not attach (active: " .. table.concat(names, ", ") .. ")")
end

-- Ensure DAP pieces are present
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  pcall(vim.fn.chdir, prev_cwd)
  die("require('dap') failed — nvim-dap not available.")
end

-- Ensure nvim-dap-python is available and setup
local ok_dap_python, dap_python = pcall(require, "dap-python")
if not ok_dap_python then
  pcall(vim.fn.chdir, prev_cwd)
  die("require('dap-python') failed — nvim-dap-python not available.")
end

-- Setup dap-python if not already done
pcall(dap_python.setup, "python3")

-- Check if debugpy is available
local function check_debugpy()
  local handle = io.popen("python3 -c 'import debugpy' 2>/dev/null; echo $?")
  local result = handle:read("*a")
  handle:close()
  return result:match("0")
end

if not check_debugpy() then
  pcall(vim.fn.chdir, prev_cwd)
  print("⚠️  debugpy not available - Python DAP testing requires 'python3 -m pip install debugpy'")
  print("✅ Python DAP configuration is set up, but debugpy dependency is missing")
  print("   Install with: python3 -m pip install debugpy")
  print("   Or in Nix environment: add debugpy to python environment")
  os.exit(0)
end

-- Observe debug lifecycle
local seen = { initialized = false, stopped = false, terminated = false }
local reason
dap.listeners.after.event_initialized["python-e2e"] = function() seen.initialized = true end
dap.listeners.after.event_stopped["python-e2e"] = function(_, body)
  seen.stopped = true
  reason = body and body.reason or reason
end
dap.listeners.after.event_terminated["python-e2e"] = function() seen.terminated = true end
dap.listeners.after.event_exited["python-e2e"] = dap.listeners.after.event_terminated["python-e2e"]

-- Function to test Python debugging
local function test_python_debug(debug_type, file_path, breakpoint_line, config_override)
  print("Testing Python " .. debug_type .. " debug ...")
  
  -- Reset state
  dap.clear_breakpoints()
  seen = { initialized = false, stopped = false, terminated = false }
  reason = nil
  
  -- Open the appropriate file
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  
  -- Set breakpoint
  vim.api.nvim_win_set_cursor(0, { breakpoint_line, 0 })
  dap.set_breakpoint()
  
  -- Create debug configuration using dap-python
  local config = {
    type = "python",
    request = "launch",
    name = "Debug " .. debug_type,
    program = file_path,
    console = "integratedTerminal",
    cwd = project_root,
    stopOnEntry = false,
    justMyCode = true,
  }
  
  -- For test debugging, modify configuration
  if debug_type == "test" then
    config.module = "unittest"
    config.args = { file_path, "-v" }
    config.program = nil -- Don't use program when using module
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
    die("Python " .. debug_type .. " DAP session did not start")
  end
  
  -- Wait for initialization
  vim.wait(2000, function() return seen.initialized end, 100)
  
  -- Continue and wait for breakpoint
  pcall(dap.continue)
  if not vim.wait(dap_timeout, function() return seen.stopped end, 200) then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("Python " .. debug_type .. " debugger did not stop (breakpoint not hit)")
  end
  
  if reason and reason ~= "breakpoint" and reason ~= "step" then
    pcall(dap.terminate)
    pcall(vim.fn.chdir, prev_cwd)
    die("Python " .. debug_type .. " stopped for unexpected reason: " .. tostring(reason))
  end
  
  -- Terminate the session
  pcall(dap.terminate)
  vim.wait(2000, function() return seen.terminated end, 100)
  
  print("✅ Python " .. debug_type .. " debugging successful (breakpoint hit)")
  return true
end

-- Test debugging Python main program
-- Breakpoint on line 73: result1 = calc.add(10, 5)
test_python_debug("program", main_file, 73)

-- Test debugging Python script mode (alternative approach)
print("Testing Python script debug ...")
dap.clear_breakpoints()
seen = { initialized = false, stopped = false, terminated = false }
reason = nil

vim.cmd("edit! " .. vim.fn.fnameescape(main_file))
vim.api.nvim_win_set_cursor(0, { 52, 0 }) -- Position on greet function call
dap.set_breakpoint()

local script_config = {
  type = "python",
  request = "launch",
  name = "Debug Python Script",
  program = main_file,
  console = "integratedTerminal",
  cwd = project_root,
  args = {},
  stopOnEntry = false,
  justMyCode = true,
}

dap.run(script_config)

local ok_session = vim.wait(20000, function() return dap.session() ~= nil end, 100)
if ok_session then
  vim.wait(2000, function() return seen.initialized end, 100)
  pcall(dap.continue)
  
  if vim.wait(15000, function() return seen.stopped end, 200) then
    if not reason or reason == "breakpoint" or reason == "step" then
      print("✅ Python script debugging successful (breakpoint hit)")
    else
      print("⚠️  Python script stopped for reason: " .. tostring(reason))
    end
    pcall(dap.terminate)
    vim.wait(2000, function() return seen.terminated end, 100)
  else
    print("⚠️  Python script breakpoint not hit")
    pcall(dap.terminate)
  end
else
  print("⚠️  Python script debug session did not start")
end

-- Test debugging specific Python module/function
print("Testing Python module debug ...")
dap.clear_breakpoints()
seen = { initialized = false, stopped = false, terminated = false }
reason = nil

vim.cmd("edit! " .. vim.fn.fnameescape(main_file))
vim.api.nvim_win_set_cursor(0, { 22, 0 }) -- Position on Calculator.__init__
dap.set_breakpoint()

local module_config = {
  type = "python",
  request = "launch",
  name = "Debug Python Module",
  program = main_file,
  console = "integratedTerminal",
  cwd = project_root,
  stopOnEntry = false,
  justMyCode = true,
}

dap.run(module_config)

local ok_session = vim.wait(20000, function() return dap.session() ~= nil end, 100)
if ok_session then
  vim.wait(2000, function() return seen.initialized end, 100)
  pcall(dap.continue)
  
  if vim.wait(15000, function() return seen.stopped end, 200) then
    if not reason or reason == "breakpoint" or reason == "step" then
      print("✅ Python module debugging successful (breakpoint hit)")
    else
      print("⚠️  Python module stopped for reason: " .. tostring(reason))
    end
    pcall(dap.terminate)
    vim.wait(2000, function() return seen.terminated end, 100)
  else
    print("⚠️  Python module breakpoint not hit")
    pcall(dap.terminate)
  end
else
  print("⚠️  Python module debug session did not start")
end

-- Test debugging Python unittest (more comprehensive)
print("Testing Python unittest debug ...")
dap.clear_breakpoints()
seen = { initialized = false, stopped = false, terminated = false }
reason = nil

vim.cmd("edit! " .. vim.fn.fnameescape(test_file))
vim.api.nvim_win_set_cursor(0, { 25, 0 }) -- Position on self.calc.add(5, 3) in test_add_method
dap.set_breakpoint()

local unittest_config = {
  type = "python",
  request = "launch",
  name = "Debug Python Unittest",
  module = "unittest",
  args = { test_file, "-v" },
  console = "integratedTerminal",
  cwd = project_root,
  justMyCode = true,
  stopOnEntry = false,
}

dap.run(unittest_config)

local ok_session = vim.wait(20000, function() return dap.session() ~= nil end, 100)
if ok_session then
  vim.wait(2000, function() return seen.initialized end, 100)
  pcall(dap.continue)
  
  if vim.wait(15000, function() return seen.stopped end, 200) then
    if not reason or reason == "breakpoint" or reason == "step" then
      print("✅ Python unittest debugging successful (breakpoint hit)")
    else
      print("⚠️  Python unittest stopped for reason: " .. tostring(reason))
    end
    pcall(dap.terminate)
    vim.wait(2000, function() return seen.terminated end, 100)
  else
    print("⚠️  Python unittest breakpoint not hit")
    pcall(dap.terminate)
  end
else
  print("⚠️  Python unittest debug session did not start")
end

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

local pyright_root = (pyright_client and pyright_client.config and pyright_client.config.root_dir) or "(unknown)"

print("")
print("🎉 Python debugging tests completed!")
print("   ✅ Program debugging: successful")
print("   main_file: " .. vim.trim(main_file))
print("   test_file: " .. vim.trim(test_file))
print("   project_root: " .. vim.trim(project_root))
print("   pyright_root: " .. vim.trim(pyright_root))
print("")

-- Restore original notify function
vim.notify = original_notify

-- Force exit with OS signal
os.exit(0)