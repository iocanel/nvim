-- Python Language Test Configuration
-- Defines Python-specific test parameters and requirements

local M = {}

-- Python LSP Configuration
M.lsp = {
  server_name = "pyright",
  timeout_env_var = "PYRIGHT_WAIT_MS",
  default_timeout = 15000,
  expected_filetype = "python",
  language = "Python",
  required_caps = {
    "completionProvider",
    "definitionProvider", 
    "hoverProvider",
  },
  optional_caps = {
    "documentFormattingProvider"
  },
}

-- Python DAP Configuration
M.dap = {
  adapter_name = "python",
  timeout_env_var = "DAP_WAIT_MS",
  default_timeout = 20000,
}

return M