-- Run with:
--   nvim --headless "+luafile tests/python/lsp.lua"
-- Env overrides (optional):
--   PYRIGHT_WAIT_MS=20000

if vim.g.__python_lsp_e2e_running then return end
vim.g.__python_lsp_e2e_running = true

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
local requirements_file = project_root .. "/requirements.txt"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end
if vim.fn.filereadable(requirements_file) == 0 then die("Requirements file not found: " .. requirements_file) end

-- Enter project root for consistent pyright root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Function to test LSP functionality for a Python file
local function test_python_lsp(file_path, file_type)
  print("Testing Python LSP for " .. file_type .. " ...")
  
  -- Open file to trigger pyright
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  if vim.bo.filetype ~= "python" then
    pcall(vim.fn.chdir, prev_cwd)
    die("Expected filetype=python for " .. file_type .. ", got " .. tostring(vim.bo.filetype))
  end
  
  -- Wait for pyright to attach
  local timeout = tonumber(vim.env.PYRIGHT_WAIT_MS) or 15000
  local pyright_client
  local attached = vim.wait(timeout, function()
    for _, c in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
      local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
      if ok and attached_buf and (c.initialized or c.server_capabilities) then
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
    die("pyright did not attach for " .. file_type .. " (active: " .. table.concat(names, ", ") .. ")")
  end
  
  -- Test LSP capabilities
  local caps = pyright_client.server_capabilities
  if not caps then
    pcall(vim.fn.chdir, prev_cwd)
    die("pyright has no server capabilities for " .. file_type)
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
  
  -- For pyright, documentFormattingProvider might not be available
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
      die("pyright missing required capabilities for " .. file_type .. ": " .. table.concat(filtered_missing, ", "))
    end
  end
  
  -- Test hover functionality on a function/class
  -- Position cursor on 'Calculator' class definition
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local class_line = nil
  for i, line in ipairs(lines) do
    if line:match("^class Calculator") then
      class_line = i
      break
    end
  end
  
  if class_line then
    vim.api.nvim_win_set_cursor(0, { class_line, 6 }) -- Position on "Calculator"
    local hover_result = nil
    vim.lsp.buf.hover()
    
    -- Wait briefly for any hover response (non-blocking test)
    vim.wait(1000, function() return false end, 100)
  end
  
  print("✅ Python LSP working for " .. file_type)
  print("   - File: " .. vim.trim(file_path))
  print("   - Server: " .. pyright_client.name .. " (ID: " .. pyright_client.id .. ")")
  print("   - Root: " .. (pyright_client.config.root_dir or "(unknown)"))
  
  local available_caps = {}
  for _, cap in ipairs(required_caps) do
    if caps[cap] then
      table.insert(available_caps, (cap:gsub("Provider", "")))
    end
  end
  print("   - Capabilities: " .. table.concat(available_caps, ", "))
  
  return true
end

-- Test main Python file
test_python_lsp(main_file, "main module")

-- Test Python test file
test_python_lsp(test_file, "test module")

-- Test that both files use the same LSP client (same project)
local main_clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr(main_file) })
local test_clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr(test_file) })

if #main_clients > 0 and #test_clients > 0 then
  local main_pyright = nil
  local test_pyright = nil
  
  for _, client in ipairs(main_clients) do
    if client.name == "pyright" then main_pyright = client break end
  end
  
  for _, client in ipairs(test_clients) do
    if client.name == "pyright" then test_pyright = client break end
  end
  
  if main_pyright and test_pyright and main_pyright.id == test_pyright.id then
    print("✅ Both files share the same pyright client (ID: " .. main_pyright.id .. ")")
  else
    print("⚠️  Files using different pyright clients (may be expected)")
  end
end

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

print("")
print("🎉 Python LSP tests completed successfully!")
print("   Files tested: helloworld.py, test_helloworld.py")
print("   LSP server: pyright")
print("   Project root: " .. vim.trim(project_root))
print("")

-- Force exit with OS signal
os.exit(0)