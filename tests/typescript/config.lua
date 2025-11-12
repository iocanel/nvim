-- TypeScript Language Test Configuration
-- Defines TypeScript-specific test parameters and requirements

local M = {}

-- TypeScript LSP Configuration
M.lsp = {
  server_name = "ts_ls",
  timeout_env_var = "TS_LS_WAIT_MS",
  default_timeout = 40000,
  expected_filetype = "typescript",
  language = "TypeScript",
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

-- TypeScript DAP Configuration
M.dap = {
  adapter_name = "pwa-node",
  timeout_env_var = "DAP_WAIT_MS",
  default_timeout = 40000,
}

return M