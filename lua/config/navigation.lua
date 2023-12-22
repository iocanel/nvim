local M = {
  previous_buffers = {}, -- Stack to hold previous buffers
  lookup_depth = 1, -- Current buffer index
  in_transition = false
};

function M.stack_push()
  local buffer_id = vim.api.nvim_get_current_buf()
  if not M.in_transition and M.is_file_buffer(buffer_id) and vim.api.nvim_buf_is_valid(buffer_id) then
    table.insert(M.previous_buffers, vim.api.nvim_get_current_buf())
    M.lookup_depth = 1
  end
end

function M.get_buffer(depth)
    if depth >= 1 and depth <= #M.previous_buffers then
        local buffer_id =  M.previous_buffers[#M.previous_buffers - depth + 1]
        if vim.api.nvim_buf_is_valid(buffer_id) then
            return buffer_id
        else
           table.remove(M.previous_buffers, #M.previous_buffers - depth + 1);
           return M.get_buffer(depth)
        end
    else
        return nil -- Invalid index
    end
end

function M.go_back()
  local current_buf = vim.api.nvim_get_current_buf()
  local buf = M.get_buffer(M.lookup_depth)
  while (current_buf == buf and M.lookup_depth < #M.previous_buffers) do
    M.lookup_depth = M.lookup_depth + 1
    buf = M.get_buffer(M.lookup_depth)
  end
  M.in_transition = true
  M.lookup_depth = M.lookup_depth + 1
  if M.lookup_depth > #M.previous_buffers then
    M.lookup_depth = #M.previous_buffers
  end
  if buf ~= nil and type(buf) == "number" then
    vim.api.nvim_set_current_buf(buf)
  end
  M.in_transition = false
end

function M.go_forward()
  local current_buf = vim.api.nvim_get_current_buf()
  local buf = M.get_buffer(M.lookup_depth)
  while (current_buf == buf and M.lookup_depth > 1) do
    M.lookup_depth = M.lookup_depth - 1
    buf = M.get_buffer(M.lookup_depth)
  end

  M.in_transition = true
  if M.lookup_depth > 1 then
    M.lookup_depth = M.lookup_depth - 1
  end
  vim.api.nvim_set_current_buf(buf)
  M.in_transition = false
end

function M.is_file_buffer(bufnr)
    -- Get the buffer type (filetype)
    local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
    -- Check if the buffer has a valid filetype
    return filetype ~= ''
end


return M;
