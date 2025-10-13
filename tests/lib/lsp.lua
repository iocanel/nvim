-- LSP Test Utilities - Common LSP testing functionality
-- Provides generic LSP client attachment, capability validation, and test patterns

local framework = dofile("tests/lib/framework.lua")
local M = {}

---Wait for LSP client to attach to current buffer
---@param server_name string Name of LSP server to wait for
---@param timeout number Timeout in milliseconds
---@param file_type_description string Description for error messages
---@param restore_cwd function Function to restore working directory on error
---@return table|nil LSP client if attached, nil otherwise
function M.wait_for_client_attachment(server_name, timeout, file_type_description, restore_cwd)
  local client
  local attached = vim.wait(timeout, function()
    for _, c in ipairs(vim.lsp.get_clients({ name = server_name })) do
      local ok, attached_buf = pcall(vim.lsp.buf_is_attached, 0, c.id)
      if ok and attached_buf and (c.initialized or c.server_capabilities) then
        client = c
        return true
      end
    end
    return false
  end, 200)
  
  if not attached then
    if restore_cwd then restore_cwd() end
    local names = {}
    for _, c in ipairs(vim.lsp.get_clients()) do 
      table.insert(names, c.name) 
    end
    framework.die(server_name .. " did not attach for " .. file_type_description .. 
                 " (active: " .. table.concat(names, ", ") .. ")")
  end
  
  return client
end

---Validate LSP client has required capabilities
---@param client table LSP client
---@param required_caps table List of required capability names
---@param optional_caps table|nil List of optional capability names
---@param file_type_description string Description for error messages
---@param restore_cwd function Function to restore working directory on error
---@return table List of available capabilities
function M.validate_capabilities(client, required_caps, optional_caps, file_type_description, restore_cwd)
  local caps = client.server_capabilities
  if not caps then
    if restore_cwd then restore_cwd() end
    framework.die(client.name .. " has no server capabilities for " .. file_type_description)
  end
  
  local missing_caps = {}
  for _, cap in ipairs(required_caps) do
    if not caps[cap] then
      table.insert(missing_caps, cap)
    end
  end
  
  -- Filter out optional capabilities from missing list
  if optional_caps and #missing_caps > 0 then
    local filtered_missing = {}
    for _, cap in ipairs(missing_caps) do
      local is_optional = false
      for _, optional_cap in ipairs(optional_caps) do
        if cap == optional_cap then
          is_optional = true
          break
        end
      end
      if not is_optional then
        table.insert(filtered_missing, cap)
      end
    end
    missing_caps = filtered_missing
  end
  
  if #missing_caps > 0 then
    if restore_cwd then restore_cwd() end
    framework.die(client.name .. " missing required capabilities for " .. file_type_description .. 
                 ": " .. table.concat(missing_caps, ", "))
  end
  
  -- Return list of available capabilities for reporting
  local available_caps = {}
  for _, cap in ipairs(required_caps) do
    if caps[cap] then
      table.insert(available_caps, (cap:gsub("Provider", "")))
    end
  end
  
  return available_caps
end

---Test hover functionality at a specific position or pattern
---@param line_number number|nil Specific line number to test hover
---@param pattern string|nil Pattern to search for hover position
---@param column_offset number|nil Column offset for hover position
---@return boolean Success status
function M.test_hover_functionality(line_number, pattern, column_offset)
  local target_line = line_number
  
  if pattern and not line_number then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
      if line:match(pattern) then
        target_line = i
        break
      end
    end
  end
  
  if target_line then
    local col = column_offset or 0
    vim.api.nvim_win_set_cursor(0, { target_line, col })
    
    -- Trigger hover (non-blocking test)
    vim.lsp.buf.hover()
    vim.wait(1000, function() return false end, 100)
    return true
  end
  
  return false
end

---Test LSP functionality for a specific file
---@param config table Configuration with server_name, file_path, file_type_description, required_caps, etc.
---@return table LSP client information
function M.test_file_lsp(config)
  framework.print_section(config.language .. " LSP for " .. config.file_type_description)
  
  -- Open file to trigger LSP
  vim.cmd("edit! " .. vim.fn.fnameescape(config.file_path))
  framework.validate_filetype(config.expected_filetype, config.file_type_description, config.restore_cwd)
  
  -- Wait for LSP client attachment
  local timeout = framework.get_timeout(config.timeout_env_var, config.default_timeout or 15000)
  local client = M.wait_for_client_attachment(
    config.server_name, 
    timeout, 
    config.file_type_description, 
    config.restore_cwd
  )
  
  -- Validate capabilities
  local available_caps = M.validate_capabilities(
    client,
    config.required_caps,
    config.optional_caps,
    config.file_type_description,
    config.restore_cwd
  )
  
  -- Test hover if configuration provided
  if config.hover_test then
    M.test_hover_functionality(
      config.hover_test.line_number,
      config.hover_test.pattern,
      config.hover_test.column_offset
    )
  end
  
  -- Print success details
  local details = {
    "File: " .. vim.trim(config.file_path),
    "Server: " .. client.name .. " (ID: " .. client.id .. ")",
    "Root: " .. (client.config.root_dir or "(unknown)"),
    "Capabilities: " .. table.concat(available_caps, ", ")
  }
  
  framework.print_success(config.language .. " LSP working for " .. config.file_type_description, details)
  
  return {
    client = client,
    available_caps = available_caps
  }
end

---Verify that multiple files share the same LSP client
---@param files table List of {file_path, description} pairs
---@param server_name string Name of the LSP server
function M.verify_shared_client(files, server_name)
  local clients = {}
  
  for i, file_info in ipairs(files) do
    local file_clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr(file_info.file_path) })
    for _, client in ipairs(file_clients) do
      if client.name == server_name then
        clients[i] = client
        break
      end
    end
  end
  
  if #clients >= 2 then
    local same_client = true
    local first_id = clients[1] and clients[1].id
    
    for i = 2, #clients do
      if not clients[i] or clients[i].id ~= first_id then
        same_client = false
        break
      end
    end
    
    if same_client and first_id then
      framework.print_success("All files share the same " .. server_name .. " client (ID: " .. first_id .. ")")
    else
      framework.print_warning("Files using different " .. server_name .. " clients (may be expected)")
    end
  end
end

return M