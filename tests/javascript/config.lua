-- JavaScript Language Test Configuration
-- Defines JavaScript-specific test parameters and requirements

local M = {}

-- JavaScript LSP Configuration
M.lsp = {
  server_name = "ts_ls",
  timeout_env_var = "TS_LS_WAIT_MS",
  default_timeout = 40000,
  expected_filetype = "javascript",
  language = "JavaScript",
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

-- JavaScript DAP Configuration
M.dap = {
  adapter_name = "pwa-node",
  timeout_env_var = "DAP_WAIT_MS",
  default_timeout = 40000,
}

return M