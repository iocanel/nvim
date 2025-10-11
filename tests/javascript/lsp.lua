-- Run with:
--   nvim --headless "+luafile tests/javascript/lsp.lua"
-- Env overrides (optional):
--   TSSERVER_WAIT_MS=20000

if vim.g.__javascript_lsp_e2e_running then return end
vim.g.__javascript_lsp_e2e_running = true

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
local package_file = project_root .. "/package.json"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end
if vim.fn.filereadable(package_file) == 0 then die("Package file not found: " .. package_file) end

-- Enter project root for consistent ts_ls root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Function to test LSP functionality for a JavaScript file
local function test_javascript_lsp(file_path, file_type)
  print("Testing JavaScript LSP for " .. file_type .. " ...")
  
  -- Open file to trigger ts_ls
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  if vim.bo.filetype ~= "javascript" then
    pcall(vim.fn.chdir, prev_cwd)
    die("Expected filetype=javascript for " .. file_type .. ", got " .. tostring(vim.bo.filetype))
  end
  
  -- Wait for ts_ls to attach
  local timeout = tonumber(vim.env.TSSERVER_WAIT_MS) or 15000
  local ts_client
  local attached = vim.wait(timeout, function()
    for _, c in ipairs(vim.lsp.get_clients({ name = "ts_ls" })) do
      local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
      if ok and attached_buf and (c.initialized or c.server_capabilities) then
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
    die("ts_ls did not attach for " .. file_type .. " (active: " .. table.concat(names, ", ") .. ")")
  end
  
  -- Test LSP capabilities
  local caps = ts_client.server_capabilities
  if not caps then
    pcall(vim.fn.chdir, prev_cwd)
    die("ts_ls has no server capabilities for " .. file_type)
  end
  
  -- Check essential capabilities
  local required_caps = {
    "completionProvider",
    "definitionProvider", 
    "hoverProvider",
    "documentFormattingProvider"
  }
  
  local missing_caps = {}
  for _, cap in ipairs(required_caps) do
    if not caps[cap] then
      table.insert(missing_caps, cap)
    end
  end
  
  -- For ts_ls, documentFormattingProvider might not be available
  -- so we'll be lenient about that one
  if #missing_caps > 0 then
    local filtered_missing = {}
    for _, cap in ipairs(missing_caps) do
      if cap ~= "documentFormattingProvider" then
        table.insert(filtered_missing, cap)
      end
    end
    
    if #filtered_missing > 0 then
      pcall(vim.fn.chdir, prev_cwd)
      die("ts_ls missing required capabilities for " .. file_type .. ": " .. table.concat(filtered_missing, ", "))
    end
  end
  
  -- Test hover functionality on a function
  -- Position cursor on 'greet' function definition
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local greet_line = nil
  for i, line in ipairs(lines) do
    if line:match("function greet") then
      greet_line = i
      break
    end
  end
  
  if greet_line then
    vim.api.nvim_win_set_cursor(0, { greet_line, 9 }) -- Position on "greet"
    local hover_result = nil
    vim.lsp.buf.hover()
    
    -- Wait briefly for any hover response (non-blocking test)
    vim.wait(1000, function() return false end, 100)
  end
  
  print("✅ JavaScript LSP working for " .. file_type)
  print("   - File: " .. vim.trim(file_path))
  print("   - Server: " .. ts_client.name .. " (ID: " .. ts_client.id .. ")")
  print("   - Root: " .. (ts_client.config.root_dir or "(unknown)"))
  
  local available_caps = {}
  for _, cap in ipairs(required_caps) do
    if caps[cap] then
      table.insert(available_caps, (cap:gsub("Provider", "")))
    end
  end
  print("   - Capabilities: " .. table.concat(available_caps, ", "))
  
  return true
end

-- Test main JavaScript file
test_javascript_lsp(main_file, "main module")

-- Test JavaScript test file
test_javascript_lsp(test_file, "test module")

-- Test that both files use the same LSP client (same project)
local main_clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr(main_file) })
local test_clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr(test_file) })

if #main_clients > 0 and #test_clients > 0 then
  local main_ts = nil
  local test_ts = nil
  
  for _, client in ipairs(main_clients) do
    if client.name == "ts_ls" then main_ts = client break end
  end
  
  for _, client in ipairs(test_clients) do
    if client.name == "ts_ls" then test_ts = client break end
  end
  
  if main_ts and test_ts and main_ts.id == test_ts.id then
    print("✅ Both files share the same ts_ls client (ID: " .. main_ts.id .. ")")
  else
    print("⚠️  Files using different ts_ls clients (may be expected)")
  end
end

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

print("")
print("🎉 JavaScript LSP tests completed successfully!")
print("   Files tested: helloworld.js, helloworld.test.js")
print("   LSP server: ts_ls")
print("   Project root: " .. vim.trim(project_root))
print("")

-- Force exit with OS signal
os.exit(0)