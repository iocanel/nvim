-- Run with:
--   nvim --headless "+luafile tests/go/lsp.lua"
-- Env overrides (optional):
--   GOPLS_WAIT_MS=20000

-- Load utilities
local framework = dofile("tests/lib/framework.lua")
local lsp_utils = dofile("tests/lib/lsp.lua")
local config = dofile("tests/go/config.lua")

if not framework.ensure_single_run('__go_lsp_e2e_running') then return end

-- Setup project paths
local this_dir = framework.get_script_dir()
local required_files = {
  main_file = "helloworld.go",
  test_file = "helloworld_test.go", 
  mod_file = "go.mod",
}
local paths = framework.setup_project_paths(this_dir, "test_project", required_files)

-- Enter project directory
local restore_cwd = framework.enter_project_dir(paths.project_root)

-- Test main Go file
local main_config = {
  server_name = config.lsp.server_name,
  file_path = paths.main_file,
  file_type_description = "main program",
  expected_filetype = config.lsp.expected_filetype,
  language = config.lsp.language,
  timeout_env_var = config.lsp.timeout_env_var,
  default_timeout = config.lsp.default_timeout,
  required_caps = config.lsp.required_caps,
  optional_caps = config.lsp.optional_caps,
  hover_test = { pattern = "fmt", column_offset = 1 },
  restore_cwd = restore_cwd,
}

local main_result = lsp_utils.test_file_lsp(main_config)

-- Test Go test file
local test_config = {
  server_name = config.lsp.server_name,
  file_path = paths.test_file,
  file_type_description = "test file",
  expected_filetype = config.lsp.expected_filetype,
  language = config.lsp.language,
  timeout_env_var = config.lsp.timeout_env_var,
  default_timeout = config.lsp.default_timeout,
  required_caps = config.lsp.required_caps,
  optional_caps = config.lsp.optional_caps,
  hover_test = { line_number = 20, column_offset = 0 },
  restore_cwd = restore_cwd,
}

local test_result = lsp_utils.test_file_lsp(test_config)

-- Test that both files use the same LSP client
local files_to_check = {
  { file_path = paths.main_file, description = "main program" },
  { file_path = paths.test_file, description = "test file" }
}
lsp_utils.verify_shared_client(files_to_check, config.lsp.server_name)

-- Print final results and cleanup
restore_cwd()
framework.print_final_results(
  "Go LSP", 
  {"helloworld.go", "helloworld_test.go"}, 
  config.lsp.server_name, 
  paths.project_root
)

framework.exit_success()