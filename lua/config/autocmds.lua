-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Floating diagnostics on hover (top right corner)
_G.diagnostic_float_enabled = true
_G.diagnostic_float_autocmd_id = nil

local function show_diagnostic_float()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  if #diagnostics == 0 then
    return
  end

  local lines = {}
  for _, d in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[d.severity]
    for _, line in ipairs(vim.split(string.format("[%s] %s", severity, d.message), "\n")) do
      table.insert(lines, line)
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end
  width = math.min(width, 80)

  local padding = 2
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    anchor = "NE",
    row = padding,
    col = vim.o.columns - padding,
    width = width,
    height = #lines,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
end

local function enable_diagnostic_float()
  if _G.diagnostic_float_autocmd_id then
    return
  end
  _G.diagnostic_float_autocmd_id = vim.api.nvim_create_autocmd("CursorHold", {
    callback = show_diagnostic_float,
  })
  _G.diagnostic_float_enabled = true
end

local function disable_diagnostic_float()
  if _G.diagnostic_float_autocmd_id then
    vim.api.nvim_del_autocmd(_G.diagnostic_float_autocmd_id)
    _G.diagnostic_float_autocmd_id = nil
  end
  _G.diagnostic_float_enabled = false
end

function _G.toggle_diagnostic_float()
  if _G.diagnostic_float_enabled then
    disable_diagnostic_float()
  else
    enable_diagnostic_float()
  end
end

enable_diagnostic_float()

local navigation = require("config.navigation")
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = navigation.stack_push,
})


-- Define the custom indentation function
local function custom_java_indent(lnum)
  local installed, java = pcall(require, 'config.indent.java');
  if installed then
    return java:indent(lnum)
  end
end

_G.custom_java_indent = custom_java_indent
-- Set up the auto-command to use the custom indentation function for Java files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    vim.bo.indentexpr = 'v:lua.custom_java_indent(v:lnum)'
  end,
})
