-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local navigation = require("config.navigation")
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = navigation.stack_push,
})
