-- Run with:
--   nvim --headless "+luafile tests/go/lsp.lua"
-- Env overrides (optional):
--   GOPLS_WAIT_MS=20000

if vim.g.__go_lsp_e2e_running then return end
vim.g.__go_lsp_e2e_running = true

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
local mod_file = project_root .. "/go.mod"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(test_file) == 0 then die("Test file not found: " .. test_file) end
if vim.fn.filereadable(mod_file) == 0 then die("Go mod file not found: " .. mod_file) end

-- Enter project root for consistent gopls root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Function to test LSP functionality for a Go file
local function test_go_lsp(file_path, file_type)
  print("Testing Go LSP for " .. file_type .. " ...")
  
  -- Open file to trigger gopls
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  if vim.bo.filetype ~= "go" then
    pcall(vim.fn.chdir, prev_cwd)
    die("Expected filetype=go for " .. file_type .. ", got " .. tostring(vim.bo.filetype))
  end
  
  -- Wait for gopls to attach
  local timeout = tonumber(vim.env.GOPLS_WAIT_MS) or 15000
  local gopls_client
  local attached = vim.wait(timeout, function()
    for _, c in ipairs(vim.lsp.get_clients({ name = "gopls" })) do
      local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
      if ok and attached_buf and (c.initialized or c.server_capabilities) then
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
    die("gopls did not attach for " .. file_type .. " (active: " .. table.concat(names, ", ") .. ")")
  end
  
  -- Test LSP capabilities
  local caps = gopls_client.server_capabilities
  if not caps then
    pcall(vim.fn.chdir, prev_cwd)
    die("gopls has no server capabilities for " .. file_type)
  end
  
  -- Check essential capabilities
  local required_caps = {
    "completionProvider",
    "definitionProvider", 
    "hoverProvider",
    "documentFormattingProvider"
  }
  
  for _, cap in ipairs(required_caps) do
    if not caps[cap] then
      pcall(vim.fn.chdir, prev_cwd)
      die("gopls missing required capability '" .. cap .. "' for " .. file_type)
    end
  end
  
  -- Test hover functionality (position on 'fmt' import)
  vim.api.nvim_win_set_cursor(0, { 4, 1 }) -- Position on "fmt"
  local hover_result = nil
  vim.lsp.buf.hover()
  
  -- Wait briefly for any hover response (non-blocking test)
  vim.wait(1000, function() return false end, 100)
  
  print("✅ Go LSP working for " .. file_type)
  print("   - File: " .. vim.trim(file_path))
  print("   - Server: " .. gopls_client.name .. " (ID: " .. gopls_client.id .. ")")
  print("   - Root: " .. (gopls_client.config.root_dir or "(unknown)"))
  print("   - Capabilities: completion, definition, hover, formatting")
  
  return true
end

-- Test main Go file
test_go_lsp(main_file, "main program")

-- Test Go test file
test_go_lsp(test_file, "test file")

-- Test that both files use the same LSP client (same project)
local main_clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr(main_file) })
local test_clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr(test_file) })

if #main_clients > 0 and #test_clients > 0 then
  local main_gopls = nil
  local test_gopls = nil
  
  for _, client in ipairs(main_clients) do
    if client.name == "gopls" then main_gopls = client break end
  end
  
  for _, client in ipairs(test_clients) do
    if client.name == "gopls" then test_gopls = client break end
  end
  
  if main_gopls and test_gopls and main_gopls.id == test_gopls.id then
    print("✅ Both files share the same gopls client (ID: " .. main_gopls.id .. ")")
  else
    print("⚠️  Files using different gopls clients (may be expected)")
  end
end

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

print("")
print("🎉 Go LSP tests completed successfully!")
print("   Files tested: helloworld.go, helloworld_test.go")
print("   LSP server: gopls")
print("   Project root: " .. vim.trim(project_root))
print("")

-- Force exit with OS signal
os.exit(0)