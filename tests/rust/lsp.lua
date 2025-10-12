-- Run with:
--   nvim --headless "+luafile tests/rust/lsp.lua"
-- Env overrides (optional):
--   RUST_ANALYZER_WAIT_MS=15000

if vim.g.__rust_lsp_e2e_running then return end
vim.g.__rust_lsp_e2e_running = true

local function die(msg)
  print(msg)
  vim.cmd.cq() -- exit non-zero
end

local uv = vim.uv or vim.loop

-- Paths
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local project_root = vim.fn.fnamemodify(this_dir .. "/test_project", ":p"):gsub("/$", "")
local main_file = project_root .. "/src/main.rs"
local lib_file = project_root .. "/src/lib.rs"
local cargo_file = project_root .. "/Cargo.toml"

if vim.fn.isdirectory(project_root) == 0 then die("Project root not found: " .. project_root) end
if vim.fn.filereadable(main_file) == 0 then die("Main file not found: " .. main_file) end
if vim.fn.filereadable(lib_file) == 0 then die("Lib file not found: " .. lib_file) end
if vim.fn.filereadable(cargo_file) == 0 then die("Cargo.toml not found: " .. cargo_file) end

-- Enter project root for consistent rust-analyzer root detection
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Function to test LSP functionality for a Rust file
local function test_rust_lsp(file_path, file_type)
  print("Testing Rust LSP for " .. file_type .. " ...")
  
  -- Open file to trigger rust-analyzer
  vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
  if vim.bo.filetype ~= "rust" then
    pcall(vim.fn.chdir, prev_cwd)
    die("Expected filetype=rust for " .. file_type .. ", got " .. tostring(vim.bo.filetype))
  end
  
  -- Wait for rust-analyzer to attach
  local timeout = tonumber(vim.env.RUST_ANALYZER_WAIT_MS) or 15000
  local rust_analyzer_client
  local attached = vim.wait(timeout, function()
    for _, c in ipairs(vim.lsp.get_clients({ name = "rust_analyzer" })) do
      local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
      if ok and attached_buf and (c.initialized or c.server_capabilities) then
        rust_analyzer_client = c
        return true
      end
    end
    return false
  end, 200)
  
  if not attached then
    pcall(vim.fn.chdir, prev_cwd)
    local names = {}
    for _, c in ipairs(vim.lsp.get_clients()) do table.insert(names, c.name) end
    die("rust-analyzer did not attach for " .. file_type .. " (active: " .. table.concat(names, ", ") .. ")")
  end
  
  -- Test LSP capabilities
  local caps = rust_analyzer_client.server_capabilities
  if not caps then
    pcall(vim.fn.chdir, prev_cwd)
    die("rust-analyzer has no server capabilities for " .. file_type)
  end
  
  print("✅ Rust LSP working for " .. file_type)
  print("   - File: " .. vim.trim(file_path))
  print("   - Server: " .. rust_analyzer_client.name .. " (ID: " .. rust_analyzer_client.id .. ")")
  print("   - Root: " .. (rust_analyzer_client.config.root_dir or "(unknown)"))
  
  return true
end

-- Test main Rust file
test_rust_lsp(main_file, "main program")

-- Test lib Rust file
test_rust_lsp(lib_file, "library file")

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

local rust_analyzer_root = "(unknown)"
for _, c in ipairs(vim.lsp.get_clients({ name = "rust_analyzer" })) do
  if c.config and c.config.root_dir then
    rust_analyzer_root = c.config.root_dir
    break
  end
end

print("")
print("🎉 Rust LSP setup tests completed!")
print("   ✅ rust-analyzer attachment for main program")
print("   ✅ rust-analyzer attachment for library file")
print("   ✅ LSP server capabilities verification")
print("   main_file: " .. vim.trim(main_file))
print("   lib_file: " .. vim.trim(lib_file))
print("   project_root: " .. vim.trim(project_root))
print("   rust_analyzer_root: " .. vim.trim(rust_analyzer_root))
print("")

-- Force exit with OS signal
os.exit(0)