-- Test Framework - Common utilities for all language tests
-- Provides path resolution, file validation, lifecycle management, and error handling

local M = {}

-- Global test state tracking
M.guards = {}
M.uv = vim.uv or vim.loop

---Exit with error message and non-zero status
---@param msg string Error message to display
function M.die(msg)
  print(msg)
  vim.cmd.cq() -- exit non-zero
end

---Ensure test only runs once by checking/setting guard variable
---@param guard_name string Name of global guard variable
function M.ensure_single_run(guard_name)
  if vim.g[guard_name] then
    return false
  end
  vim.g[guard_name] = true
  return true
end

---Get absolute path to current test script directory
---@return string Absolute path to test script directory
function M.get_script_dir()
  return vim.fn.fnamemodify(debug.getinfo(2, "S").source:sub(2), ":p:h")
end

---Resolve and validate project paths
---@param test_dir string Directory containing the test script
---@param project_dir string Name of the project directory (default: "test_project")
---@param required_files table List of required files relative to project root
---@return table Project paths with validation
function M.setup_project_paths(test_dir, project_dir, required_files)
  project_dir = project_dir or "test_project"
  local project_root = vim.fn.fnamemodify(test_dir .. "/" .. project_dir, ":p"):gsub("/$", "")

  if vim.fn.isdirectory(project_root) == 0 then
    M.die("Project root not found: " .. project_root)
  end

  local paths = { project_root = project_root }

  -- Validate and populate required files
  for name, relative_path in pairs(required_files) do
    local full_path = project_root .. "/" .. relative_path
    if vim.fn.filereadable(full_path) == 0 then
      M.die(name:gsub("_", " "):gsub("^%l", string.upper) .. " not found: " .. full_path)
    end
    paths[name] = full_path
  end

  return paths
end

---Change to project directory and return function to restore
---@param project_root string Project root directory path
---@return function Function to restore previous working directory
function M.enter_project_dir(project_root)
  local prev_cwd = M.uv.cwd()
  local ok, err = pcall(vim.fn.chdir, project_root)
  if not ok then
    M.die("Failed to change to project directory: " .. tostring(err))
  end

  return function()
    pcall(vim.fn.chdir, prev_cwd)
  end
end

---Get timeout value from environment variable or default
---@param env_var string Environment variable name
---@param default number Default timeout in milliseconds
---@return number Timeout value in milliseconds
function M.get_timeout(env_var, default)
  return tonumber(vim.env[env_var]) or default
end

---Validate file has expected filetype
---@param expected_filetype string Expected filetype
---@param file_type_description string Description for error message
---@param restore_cwd function Function to restore working directory
function M.validate_filetype(expected_filetype, file_type_description, restore_cwd)
  if vim.bo.filetype ~= expected_filetype then
    if restore_cwd then restore_cwd() end
    M.die("Expected filetype=" .. expected_filetype .. " for " .. file_type_description ..
          ", got " .. tostring(vim.bo.filetype))
  end
end

---Print test section header
---@param message string Header message
function M.print_section(message)
  print("Testing " .. message .. " ...")
end

---Print success message with details
---@param main_message string Main success message
---@param details table Optional details to display
function M.print_success(main_message, details)
  print("✅ " .. main_message)
  if details then
    for _, detail in ipairs(details) do
      print("   - " .. detail)
    end
  end
end

---Print warning message
---@param message string Warning message
function M.print_warning(message)
  print("⚠️  " .. message)
end

---Print final test results
---@param test_name string Name of the test suite
---@param files_tested table List of files that were tested
---@param server_name string Name of the server tested
---@param project_root string Project root path
function M.print_final_results(test_name, files_tested, server_name, project_root)
  print("")
  print("🎉 " .. test_name .. " tests completed successfully!")
  print("   Files tested: " .. table.concat(files_tested, ", "))
  if server_name then
    print("   Server: " .. server_name)
  end
  print("   Project root: " .. vim.trim(project_root))
  print("")
end

---Force exit with success status
function M.exit_success()
  os.exit(0)
end

return M
