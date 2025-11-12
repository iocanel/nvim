-- Java Language Test Configuration
-- Defines Java-specific test parameters and requirements

local M = {}

-- Java LSP Configuration
M.lsp = {
  server_name = "jdtls",
  timeout_env_var = "JDTLS_WAIT_MS",
  default_timeout = 50000,
  expected_filetype = "java",
  language = "Java",
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

-- Java DAP Configuration
M.dap = {
  adapter_name = "java",
  timeout_env_var = "DAP_WAIT_MS",
  default_timeout = 60000,
}

return M