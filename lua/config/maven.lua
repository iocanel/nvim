local Path = require('plenary.path')
local project = require('config.project')
local is_windows = vim.loop.os_uname().version:match('Windows')

local M = {
  sep = is_windows and '\\' or '/',
  mvnw = is_windows and 'mvnw.cmd' or './mvnw'
};

vim.g.maven = vim.g.maven or {
  profile = nil
};

--
-- quote the expression for use in gsub
--
function M.quote(expr)
  return expr:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?%/])", "%%%1")
end

--
-- join pats (borrowed from jdtls)
--
function M.join(...)
  local result = table.concat(vim.tbl_flatten {...}, M.sep):gsub(M.sep .. '+', M.sep)
  return result
end

--
-- get the module root directory using pom.xml
--
function M.find_module_root()
  return project.find_root({'pom.xml'})
end

--
-- get the module name / artifact id from the module pom.xml
--
function M.get_module_name()
  local root = M.find_module_root()
  local pom = M.join(root, 'pom.xml')
  local f = io.open(pom, 'r')
  local content = f:read('*a')
  f:close()

  -- Remove all <parent> and <dependency> elements
  content = content:gsub('<parent>.-</parent>', '')
  content = content:gsub('<dependency>.-</dependency>', '')

  -- Find the <artifactId> tag
  return content:match('<artifactId>(.-)</artifactId>')
end

--
-- Run maven goals in the specified directory
--
function M.build(goals, module, resume, also_make, dir)
  goals = goals or "clean install"
  local project_root = project.find_root()
  dir = dir or project_root or M.find_module_root()
  local goals_with_flags = goals

  local loaded_maven = project.load_project_settings('maven')
  if loaded_maven then
    vim.g.maven = loaded_maven
  end

  if module == "<current>" then
    module = M.get_module_name()
  end

  if resume then
    goals_with_flags = "-rf :" .. (module or M.get_module_name()) .. " " .. goals_with_flags
  elseif module then
    goals_with_flags = "-pl :" .. module .. " " .. goals_with_flags
  end

  if module and also_make then
    goals_with_flags = "-am " .. goals_with_flags
  end

  if vim.g.maven.profile then
    goals_with_flags = "-P" .. vim.g.maven.profile .. " " .. goals_with_flags
  end

  if not dir or dir == "" then
    print("Directory not specified!")
    return
  end

  local toggleterm = require("toggleterm")
  -- check if mvnw exists in the dir and use that
  if project_root and vim.loop.fs_stat(M.join(dir, M.mvnw)) then
    toggleterm.exec(M.mvnw .. ' ' .. goals_with_flags, 0, 10, dir)
  elseif project_root and vim.loop.fs_stat(M.join(project_root, 'mvnw')) then
    toggleterm.exec(M.join(project_root, M.mvnw .. ' ' .. goals_with_flags), 0, 10, dir)
  else
    toggleterm.exec("mvn " .. goals_with_flags, 0, 10, dir)
  end
end

-- return the fully qualified class name of the current buffer
-- the function removes the path to sources (e.g. src/main/java or src/test/java)
-- and the file extension and finally converts filet sepators to dots
function M.get_fully_qualified_class_name()
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  local root = project.find_root()
  local src = M.join(root, 'src')
  local test = M.join(src, 'test')
  local main = M.join(src, 'main')
  local java = M.join(main, 'java')
  local test_java = M.join(test, 'java')
  -- handle the pressence of '/' or '\' in the path
  return bufname:gsub(M.quote(java), ''):gsub(M.quote(test_java), ''):gsub('.java', ''):gsub(M.sep, '.'):gsub('^[\\.]',''):gsub('[ ]+','') .. ''
end

--
-- return the qualified class name at point using treesitter
--
function M.get_class_name_at_point()
  local parser = vim.treesitter.get_parser(0, "java")
  local tree = parser:parse()[1] -- get the first syntax tree

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local root = tree:root()
  local node = root:named_descendant_for_range(row, col, row, col)

  -- Traverse up to find the class declaration
  while node do
    if node:type() == "class_declaration" then
      local class_name_node = node:field("name")[1]
      if class_name_node then
        local class_name = vim.treesitter.query.get_node_text(class_name_node, 0)
        return class_name
      end
    end
    node = node:parent()
  end

  -- Fallback: find the first class declaration in the file if no enclosing class is found
  local query = vim.treesitter.query.parse("java", [[
        (class_declaration name: (identifier) @classname)
        ]])

  for id, match, metadata in query:iter_matches(root, 0) do
    for _, node in pairs(match) do
      if node:type() == "identifier" then
        local class_name = vim.treesitter.query.get_node_text(node, 0)
        return class_name
      end
    end
  end
  return nil -- return nil if no class declaration is found
end

function M.get_method_name_at_point()
  local parser = vim.treesitter.get_parser(0, "java")
  local tree = parser:parse()[1] -- get the first syntax tree

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local root = tree:root()
  local node = root:named_descendant_for_range(row, col, row, col)

  -- Traverse up to find the method declaration
  while node do
    if node:type() == "method_declaration" then
      local method_name_node = node:field("name")[1]
      if method_name_node then
        local method_name = vim.treesitter.query.get_node_text(method_name_node, 0)
        return method_name
      end
    end
    node = node:parent()
  end

  return nil -- return nil if no method declaration is found
end

--
-- return the profiles defined in the pom.xml
--
function M.get_profiles()
  local root = M.find_module_root()
  local pom = M.join(root, 'pom.xml')
  local f = io.open(pom, 'r')
  local content = f:read('*a')
  f:close()

  local profiles = {}
  for profile in content:gmatch('<profile>(.-)</profile>') do
    local id = profile:match('<id>(.-)</id>')
    if id then
      table.insert(profiles, id)
    end
  end

  return profiles
end

function M.select_profile()
  local profiles = M.get_profiles()

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local sorters = require('telescope.sorters')
  local actions_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = 'Select a profile',
    finder = finders.new_table({
      results = profiles,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      map('i', '<CR>', function()
        local selection = actions_state.get_selected_entry()
        -- Do something with the selected profile
        local m = vim.g.maven
        m.profile = selection.value
        vim.g.maven = m
        project.save_project_settings(vim.g.maven, 'maven')
        vim.api.nvim_buf_delete(prompt_bufnr, {force = true})
      end)

      return true
    end,
  }):find()

end

function M.print_fqcn()
  print(M.get_fully_qualified_class_name())
end

function M.print_class_name()
  print(M.get_class_name_at_point())
end

function M.print_method_name()
  print(M.get_method_name_at_point())
end

function M.print_root()
  print(project.find_root())
end

function M.print_module_root()
  print(M.find_module_root())
end

function M.print_module_name()
  print(M.get_module_name())
end

-- define vim command to print the fully qualified class name of the current buffer
vim.cmd('command! JavaFQCN lua require("config.maven").print_fqcn()')
vim.cmd('command! JavaClass lua require("config.maven").print_class_name()')
vim.cmd('command! JavaMethod lua require("config.maven").print_method_name()')
vim.cmd('command! MavenModuleName lua require("config.maven").print_module_name()')
vim.cmd('command! MavenCleanInstall lua require("config.maven").build("clean install")')
vim.cmd('command! MavenModuleInstall lua require("config.maven").build("clean install", "<current>")')
vim.cmd('command! MavenModuleResumeFrom lua require("config.maven").build("clean install", "<current>", true)')
vim.cmd('command! MavenModuleAlsoMake lua require("config.maven").build("clean install", "<current>", false, true)')
vim.cmd('command! MavenSetProfile lua require("config.maven").select_profile()')

return M;
