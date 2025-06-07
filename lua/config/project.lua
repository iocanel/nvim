local Path = require('plenary.path')
local is_windows = vim.loop.os_uname().version:match('Windows')
local build_system = nil

local M = {
  sep = is_windows and '\\' or '/',
};

-- Join paths (borrowed from jdtls)
function M.join(...)
  local result = table.concat(vim.tbl_flatten {...}, M.sep):gsub(M.sep .. '+', M.sep)
  return result
end

-- Get project root directory using .git
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

-- Loads project settings from a file in the .nvim directory
function M.load_project_settings(name, default_settings)
  local project_dir = M.find_root()
  if project_dir == nil then
    return default_settings
  end
  local settings_dir = Path:new(project_dir .. '/.nvim')
  if settings_dir:exists() then
    local file_path = settings_dir:joinpath(name .. '.lua')
    if file_path:exists() then
      local settings = dofile(file_path:absolute())
      return settings
    end
  end
  return default_settings
end

-- Saves project settings to a file in the .nvim directory
function M.save_project_settings(settings, name)
  local project_dir = Path:new(vim.fn.getcwd() .. '/.nvim')

  -- Ensure the .nvim directory exists
  if not project_dir:exists() then
    project_dir:mkdir()
  end

  local file_path = project_dir:joinpath(name .. '.lua')

  -- Serialize the Lua table to a Lua code string
  local settings_str = "return {\n"
  for key, value in pairs(settings) do
    settings_str = settings_str .. string.format("    %s = %q,\n", key, value)
    settings_str = settings_str:gsub("\"true\"", "true"):gsub("\"false\"", "false")
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

function M.set_build_system(b)
  M.build_system = b
end

-- Delegate to build_system for project name
function M.get_project_name()
  if M.build_system == nil then
    return require('config.maven').get_project_name()
  end
  return M.build_system.get_project_name()
end

-- Delegate to build_system for module name
function M.get_module_name()
  if M.build_system == nil then
    return require('config.maven').get_module_name()
  end
  return M.build_system.get_project_name()
end

return M
