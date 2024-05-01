local Path = require('plenary.path')
local is_windows = vim.loop.os_uname().version:match('Windows')

local M = {
  sep = is_windows and '\\' or '/',
};

--
-- join pats (borrowed from jdtls)
--
function M.join(...)
  local result = table.concat(vim.tbl_flatten {...}, M.sep):gsub(M.sep .. '+', M.sep)
  return result
end

--
--
-- get project root directory using .git
-- it's borrowed from jdtls
--
function M.find_root(markers)
  markers = markers or {'.git'}
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  local dirname = vim.fn.fnamemodify(bufname, ':p:h')
  local getparent = function(p)
    return vim.fn.fnamemodify(p, ':h')
  end
  while getparent(dirname) ~= dirname do
    for _, marker in ipairs(markers) do
      if vim.loop.fs_stat(M.join(dirname, marker)) then
        return dirname
      end
    end
    dirname = getparent(dirname)
  end
end


--
-- loads project settings from a file in the .nvim directory
-- name is the name of the lua file to load from .nvim/<name>.lua
--
function M.load_project_settings(name)
  local project_dir = Path:new(M.find_root() .. '/.nvim')
  local file_path = project_dir:joinpath(name .. '.lua')
  if project_dir:exists() then
    if file_path:exists() then
      local settings = dofile(file_path:absolute())
      return settings
    else
    end
  end
  return nil
end

--
-- saves project settings to a file in the .nvim directory
-- settings is a Lua table
-- name is the name of the file
--
function M.save_project_settings(settings, name)
  local project_dir = Path:new(vim.fn.getcwd() .. '/.nvim')

  -- Ensure the .nvim directory exists
  if not project_dir:exists() then
    -- Create the directory if it does not exist
    project_dir:mkdir()
  end

  local file_path = project_dir:joinpath(name .. '.lua')

  -- Serialize the Lua table to a Lua code string
  local settings_str = "return {\n"
  for key, value in pairs(settings) do
    settings_str = settings_str .. string.format("    %s = %q,\n", key, value)
  end
  settings_str = settings_str .. "}\n"

  -- Write the serialized string to maven.lua
  local file, err = io.open(file_path:absolute(), "w")
  if file then
    file:write(settings_str)
    file:close()
    print("Maven settings saved successfully.")
  else
    print("Error saving settings: " .. err)
  end
end

return M
