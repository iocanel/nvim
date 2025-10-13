-- Go Language Test Configuration
-- Defines Go-specific test parameters and requirements

local M = {}

-- Go LSP Configuration
M.lsp = {
  server_name = "gopls",
  timeout_env_var = "GOPLS_WAIT_MS",
  default_timeout = 15000,
  expected_filetype = "go",
  language = "Go",
  required_caps = {
    "completionProvider",
    "definitionProvider",
    "hoverProvider",
    "documentFormattingProvider"
  },
  optional_caps = {},
}

-- Go DAP Configuration
M.dap = {
  adapter_name = "go",
  timeout_env_var = "DAP_WAIT_MS",
  default_timeout = 20000,
}

return M
