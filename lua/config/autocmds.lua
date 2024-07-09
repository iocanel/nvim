-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

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
