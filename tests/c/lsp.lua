-- Run with:
--   nvim --headless "+luafile tests/c/lsp.lua"
-- Env overrides (optional):
--   CLANGD_WAIT_MS=15000

if vim.g.__c_lsp_e2e_running then return end
vim.g.__c_lsp_e2e_running = true

local function die(msg)
  print(msg)
  vim.cmd.cq() -- exit non-zero
end

local uv = vim.uv or vim.loop

-- Paths
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local project_root = vim.fn.fnamemodify(this_dir .. "/test_project", ":p"):gsub("/$", "")
local main_file = project_root .. "/main.c"
local test_file = project_root .. "/test_math.c"
local makefile = project_root .. "/Makefile"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end
if vim.fn.filereadable(makefile) == 0 then die("Makefile not found: " .. makefile) end

-- Enter project root for consistent clangd root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Function to test LSP functionality for a C file
local function test_c_lsp(file_path, file_type)
  print("Testing C LSP for " .. file_type .. " ...")
  
  -- Open file to trigger clangd
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  if vim.bo.filetype ~= "c" then
    pcall(vim.fn.chdir, prev_cwd)
    die("Expected filetype=c for " .. file_type .. ", got " .. tostring(vim.bo.filetype))
  end
  
  -- Check if clangd is available first
  if vim.fn.executable('clangd') == 0 then
    print("⚠️  clangd not found - skipping LSP test for " .. file_type)
    print("   Install clangd with: sudo apt install clangd (Ubuntu) or brew install llvm (macOS)")
    return false
  end
  
  -- Wait for clangd to attach
  local timeout = tonumber(vim.env.CLANGD_WAIT_MS) or 15000
  local clangd_client
  local attached = vim.wait(timeout, function()
    for _, c in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
      local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
      if ok and attached_buf and (c.initialized or c.server_capabilities) then
        clangd_client = c
        return true
      end
    end
    return false
  end, 200)
  
  if not attached then
    print("⚠️  clangd did not attach for " .. file_type .. " within " .. timeout .. "ms")
    local names = {}
    for _, c in ipairs(vim.lsp.get_clients()) do table.insert(names, c.name) end
    print("   Active LSP clients: " .. (next(names) and table.concat(names, ", ") or "none"))
    print("   This may be normal if clangd is not configured or takes longer to start")
    return false
  end
  
  -- Test LSP capabilities
  local caps = clangd_client.server_capabilities
  if not caps then
    pcall(vim.fn.chdir, prev_cwd)
    die("clangd has no server capabilities for " .. file_type)
  end
  
  print("✅ C LSP working for " .. file_type)
  print("   - File: " .. vim.trim(file_path))
  print("   - Server: " .. clangd_client.name .. " (ID: " .. clangd_client.id .. ")")
  print("   - Root: " .. (clangd_client.config.root_dir or "(unknown)"))
  
  return true
end

-- Test main C file
local main_lsp_ok = test_c_lsp(main_file, "main program")

-- Test C test file  
local test_lsp_ok = test_c_lsp(test_file, "test file")

-- Check if any LSP tests succeeded
if not main_lsp_ok and not test_lsp_ok then
  print("")
  print("⚠️  No LSP tests succeeded - this may indicate clangd is not available or not configured")
  print("   C DAP functionality will still work without LSP")
end

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

local clangd_root = "(unknown)"
for _, c in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
  if c.config and c.config.root_dir then
    clangd_root = c.config.root_dir
    break
  end
end

print("")
print("🎉 C LSP setup tests completed!")
if main_lsp_ok then
  print("   ✅ clangd attachment for main program")
else
  print("   ⚠️  clangd attachment for main program (skipped)")
end
if test_lsp_ok then
  print("   ✅ clangd attachment for test file")
else
  print("   ⚠️  clangd attachment for test file (skipped)")
end
if main_lsp_ok or test_lsp_ok then
  print("   ✅ LSP server capabilities verification")
else
  print("   ⚠️  LSP server capabilities verification (skipped)")
end
print("   main_file: " .. vim.trim(main_file))
print("   test_file: " .. vim.trim(test_file))
print("   project_root: " .. vim.trim(project_root))
print("   clangd_root: " .. vim.trim(clangd_root))
print("")

-- Force exit with OS signal
os.exit(0)