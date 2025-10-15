-- Rust Language Test Configuration
-- Defines Rust-specific test parameters and requirements

local M = {}

-- Rust LSP Configuration
M.lsp = {
  server_name = "rust_analyzer",
  timeout_env_var = "RUST_ANALYZER_WAIT_MS",
  default_timeout = 20000,
  expected_filetype = "rust",
  language = "Rust",
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

-- Rust DAP Configuration
M.dap = {
  adapter_name = "codelldb",
  timeout_env_var = "DAP_WAIT_MS",
  default_timeout = 60000,
}

return M