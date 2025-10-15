-- C Language Test Configuration
-- Defines C-specific test parameters and requirements

local M = {}

-- C LSP Configuration
M.lsp = {
  server_name = "clangd",
  timeout_env_var = "CLANGD_WAIT_MS",
  default_timeout = 15000,
  expected_filetype = "c",
  language = "C",
  required_caps = {
    "textDocumentSync"
  },
  optional_caps = {
    "hoverProvider",
    "definitionProvider", 
    "referencesProvider",
    "documentSymbolProvider",
    "workspaceSymbolProvider"
  },
}

-- C DAP Configuration
M.dap = {
  adapter_name = "codelldb",
  timeout_env_var = "DAP_WAIT_MS",
  default_timeout = 15000,
}

return M