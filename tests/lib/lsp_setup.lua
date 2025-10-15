-- LSP Setup Utilities - Common LSP initialization functionality
-- Provides shared LSP setup logic that can be reused across LSP and DAP tests

local framework = dofile("tests/lib/framework.lua")
local M = {}

---Setup and wait for LSP client to attach
---@param config table LSP configuration
---@return table LSP client that was attached
function M.setup_and_wait_for_lsp(config)
  -- Open the file to trigger LSP attachment
  vim.cmd.edit(vim.fn.fnameescape(config.file_path))
  framework.validate_filetype(config.expected_filetype, config.file_type_description)
  
  local timeout = tonumber(vim.env[config.timeout_env_var]) or config.default_timeout
  local client
  
  print("Waiting for " .. config.server_name .. " to attach...")
  
  local attached = vim.wait(timeout, function()
    for _, c in ipairs(vim.lsp.get_clients({ name = config.server_name })) do
      local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
      if ok and attached_buf and c.initialized then
        -- For JDTLS, wait for basic capabilities to be available
        if config.server_name == "jdtls" then
          local caps = c.server_capabilities or {}
          local has_basic_caps = caps.hoverProvider 
                              or caps.definitionProvider 
                              or caps.textDocumentSync ~= nil
                              or caps.documentSymbolProvider
          if has_basic_caps then
            client = c
            return true
          end
        else
          -- For other LSP servers, just check if initialized
          client = c
          return true
        end
      end
    end
    return false
  end, 1000)
  
  if not attached then
    framework.die(config.server_name .. " did not attach within timeout")
  end
  
  -- Additional wait for JDTLS stability
  if config.server_name == "jdtls" then
    vim.wait(2000, function() return false end, 100)
  end
  
  print("✅ " .. config.server_name .. " attached and ready")
  return client
end

---Create LSP config from language config
---@param lang_config table Language-specific configuration
---@param file_path string Path to file for LSP testing
---@param description string Description of the file being tested
---@return table LSP configuration ready for setup
function M.make_lsp_config(lang_config, file_path, description)
  return {
    server_name = lang_config.lsp.server_name,
    file_path = file_path,
    file_type_description = description,
    expected_filetype = lang_config.lsp.expected_filetype,
    language = lang_config.lsp.language,
    timeout_env_var = lang_config.lsp.timeout_env_var,
    default_timeout = lang_config.lsp.default_timeout,
    required_caps = lang_config.lsp.required_caps,
    optional_caps = lang_config.lsp.optional_caps,
  }
end

return M