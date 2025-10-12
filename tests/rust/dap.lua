-- Run with:
--   nvim --headless "+luafile tests/rust/dap.lua"

if vim.g.__rust_dap_e2e_running then return end
vim.g.__rust_dap_e2e_running = true

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

-- Enter project root for consistent behavior
local prev_cwd = uv.cwd()
pcall(vim.fn.chdir, project_root)

-- Test that DebugDwim command exists
print("Testing DebugDwim command availability ...")
local ok, err = pcall(function()
  local commands = vim.api.nvim_get_commands({})
  if commands.DebugDwim then
    print("✅ DebugDwim command is available")
  else
    error("DebugDwim command not found")
  end
end)

if not ok then
  pcall(vim.fn.chdir, prev_cwd)
  die("DebugDwim command test failed: " .. tostring(err))
end

-- Test Rust filetype detection
print("Testing Rust filetype detection ...")
vim.cmd("edit! " .. vim.fn.fnameescape(main_file))
if vim.bo.filetype ~= "rust" then
  pcall(vim.fn.chdir, prev_cwd)
  die("Expected filetype=rust for main.rs, got " .. tostring(vim.bo.filetype))
end
print("✅ Rust filetype detected correctly")

-- Test that DebugDwim can work with Rust files  
print("Testing DebugDwim with Rust files ...")
local ok, err = pcall(function()
  require('config.dap.dwim')
  local rust_dap = require('config.dap.rust')
  
  -- Test that Rust DAP module is loaded and has required interface
  if type(rust_dap.is_filetype_supported) == "function" and
     type(rust_dap.is_test_file) == "function" and
     type(rust_dap.get_debug_command) == "function" then
    print("✅ Rust DAP module has required interface")
  else
    error("Rust DAP module missing required interface functions")
  end
end)

if not ok then
  pcall(vim.fn.chdir, prev_cwd)
  die("DebugDwim Rust integration test failed: " .. tostring(err))
end

-- Ensure DAP pieces are present
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  pcall(vim.fn.chdir, prev_cwd)
  die("require('dap') failed — nvim-dap not available.")
end

-- Test DAP configuration is loaded
print("Testing Rust DAP configuration ...")
local dap_configs = dap.configurations.rust or {}
if #dap_configs > 0 then
  print("✅ Rust DAP configurations loaded (" .. #dap_configs .. " configs)")
  for i, config in ipairs(dap_configs) do
    print("   " .. i .. ". " .. (config.name or "unnamed"))
  end
else
  pcall(vim.fn.chdir, prev_cwd)
  die("No Rust DAP configurations found - DAP setup failed")
end

-- Print final success
pcall(vim.fn.chdir, prev_cwd)

print("")
print("🎉 Rust DAP setup tests completed!")
print("   ✅ DebugDwim command availability")
print("   ✅ Rust filetype detection")
print("   ✅ DebugDwim Rust integration")
print("   ✅ DAP configuration loading")
print("   💡 Note: DebugDwim automatically chooses Rust commands based on context")
print("   main_file: " .. vim.trim(main_file))
print("   lib_file: " .. vim.trim(lib_file))
print("   project_root: " .. vim.trim(project_root))
print("")

-- Force exit with OS signal
os.exit(0)