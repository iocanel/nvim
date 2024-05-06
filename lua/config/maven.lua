local project = require('config.project')
local is_windows = vim.loop.os_uname().version:match('Windows')

local M = {
  sep = is_windows and '\\' or '/',
  mvnw = is_windows and 'mvnw.cmd' or './mvnw',
  default_settings = {
    profile = nil,
    clean = false,
    skip_tests = false,
    errors = false,
    offline = false,
  },
  settings = nil;
};

M.settings = project.load_project_settings('maven', M.default_settings)
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
function M.get_module_name(root)
  root = root or M.find_module_root()
  local pom = M.join(root, 'pom.xml')
  local f = io.open(pom, 'r')
  if f == nil then
    return nil
  end
  local content = f:read('*a')
  f:close()

  -- Remove all <parent> and <dependency> elements
  content = content:gsub('<parent>.-</parent>', '')
  content = content:gsub('<dependency>.-</dependency>', '')

  -- Find the <artifactId> tag
  return content:match('<artifactId>(.-)</artifactId>')
end

--
-- get the project name
--
function M.get_project_name()
  local root = project.find_root()
  return M.get_module_name(root)
end

--
-- Run maven goals in the specified directory
--
function M.build(goals, module, resume, also_make, dir)
  goals = goals or "install"
  local project_root = project.find_root()
  dir = dir or project_root or M.find_module_root()
  M.settings = project.load_project_settings('maven', M.default_settings)

  -- if user explicitly requested the <current> module, then replace it with the actual module name
  if module == "<current>" then
    module = M.get_module_name()
  end

  -- handle clean flag
  if M.settings.clean and goals ~= "clean" then
    goals = "clean " .. goals
  end

  -- handle skip tests flag
  if M.settings.skip_tests and not goals:find("test") then
    goals = goals .. " -DskipTests"
  end

  -- handle errors flag
  if M.settings.errors then
    goals = goals .. " -e"
  end

  -- handle offline flag
  if M.settings.offline then
    goals = goals .. " -o"
  end

  if resume then
    goals = "-rf :" .. (module or M.get_module_name()) .. " " .. goals
  elseif module then
    goals = "-pl :" .. module .. " " .. goals
  end

  if module and also_make then
    goals = "-am " .. goals
  end

  if M.settings.profile then
    goals = "-P" .. M.settings.profile .. " " .. goals
  end

  if not dir or dir == "" then
    print("Directory not specified!")
    return
  end

  local toggleterm = require("toggleterm")
  -- check if mvnw exists in the dir and use that
  if project_root and vim.loop.fs_stat(M.join(dir, M.mvnw)) then
    toggleterm.exec(M.mvnw .. ' ' .. goals, 0, 10, dir)
  elseif project_root and vim.loop.fs_stat(M.join(project_root, 'mvnw')) then
    toggleterm.exec(M.join(project_root, M.mvnw .. ' ' .. goals), 0, 10, dir)
  else
    toggleterm.exec("mvn " .. goals, 0, 10, dir)
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
        local m = M.settings
        m.profile = selection.value
        M.settings = m
        project.save_project_settings(M.settings, 'maven')
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


--
-- Test
--

function M.surefire_test_class()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  M.build("test -Dtest=" .. class_name, module)
end

function M.surefire_debug_class()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  M.build("test -Dtest=" .. class_name .. " -Dmaven.surefire.debug", module)
  vim.cmd('JavaDebugAttachRemote')
end

function M.surefire_test_method()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  local method_name = M.get_method_name_at_point()
  M.build("test -Dtest=" .. class_name .. '#' .. method_name, module)
end

function M.surefire_debug_method()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  local method_name = M.get_method_name_at_point()
  M.build("test -Dtest=" .. class_name .. '#' .. method_name .. " -Dmaven.surefire.debug", module)
  vim.cmd('JavaDebugAttachRemote')
end

function M.failsafe_test_class()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  M.build("test -Dtest=" .. class_name, module)
end

function M.failsafe_debug_class()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  M.build("test -Dtest=" .. class_name .. " -Dmaven.failsafe.debug", module)
  vim.cmd('JavaDebugAttachRemote')
end

function M.failsafe_test_method()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  local method_name = M.get_method_name_at_point()
  M.build("test -Dtest=" .. class_name .. '#' .. method_name, module)
end

function M.failsafe_debug_method()
  local module = M.get_module_name()
  local class_name = M.get_class_name_at_point()
  local method_name = M.get_method_name_at_point()
  M.build("test -Dtest=" .. class_name .. '#' .. method_name .. " -Dmaven.failsafe.debug", module)
  vim.cmd('JavaDebugAttachRemote')
end


--
-- Toogle
--

function M.toggle_clean()
  local m = M.settings
  m.clean = not m.clean
  M.settings = m
  project.save_project_settings(M.settings, 'maven')
end

function M.toggle_skip_tests()
  local m = M.settings
  m.skip_tests = not m.skip_tests
  M.settings = m
  project.save_project_settings(M.settings, 'maven')
end

function M.toggle_errors()
  local m = M.settings
  m.errors = not m.errors
  M.settings = m
  project.save_project_settings(M.settings, 'maven')
end

function M.toggle_offline()
  local m = M.settings
  m.offline = not m.offline
  M.settings = m
  project.save_project_settings(M.settings, 'maven')
end

-- define vim command to print the fully qualified class name of the current buffer
vim.cmd('command! JavaFQCN lua require("config.maven").print_fqcn()')
vim.cmd('command! JavaClass lua require("config.maven").print_class_name()')
vim.cmd('command! JavaMethod lua require("config.maven").print_method_name()')
vim.cmd('command! MavenModuleName lua require("config.maven").print_module_name()')
vim.cmd('command! MavenSetProfile lua require("config.maven").select_profile()')

vim.cmd('command! MavenProjectClean lua require("config.maven").build("clean")')
vim.cmd('command! MavenProjectPackage lua require("config.maven").build("package")')
vim.cmd('command! MavenProjectInstall lua require("config.maven").build("install")')

vim.cmd('command! MavenModuleClean lua require("config.maven").build("clean", "<current>")')
vim.cmd('command! MavenModulePackage lua require("config.maven").build("package", "<current>")')
vim.cmd('command! MavenModuleInstall lua require("config.maven").build("install", "<current>")')
vim.cmd('command! MavenModuleAlsoMake lua require("config.maven").build("clean install", "<current>", false, true)')
vim.cmd('command! MavenModuleResumeFrom lua require("config.maven").build("clean install", "<current>", true)')

vim.cmd('command! MavenSureFireTestClass lua require("config.maven").surefire_test_class()')
vim.cmd('command! MavenSureFireTestMethod lua require("config.maven").surefire_test_method()')
vim.cmd('command! MavenSureFireDebugClass lua require("config.maven").surefire_debug_class()')
vim.cmd('command! MavenSureFireDebugMethod lua require("config.maven").surefire_debug_method()')

vim.cmd('command! MavenFailSafeTestClass lua require("config.maven").failsafe_test_class()')
vim.cmd('command! MavenFailSafeTestMethod lua require("config.maven").failsafe_test_method()')
vim.cmd('command! MavenFailSafeDebugClass lua require("config.maven").failsafe_debug_class()')
vim.cmd('command! MavenFailSafeDebugMethod lua require("config.maven").failsafe_debug_method()')

vim.cmd('command! MavenToggleClean lua require("config.maven").toggle_clean()')
vim.cmd('command! MavenToggleSkipTests lua require("config.maven").toggle_skip_tests()')
vim.cmd('command! MavenToggleErrors lua require("config.maven").toggle_errors()')
vim.cmd('command! MavenToggleOffline lua require("config.maven").toggle_offline()')


local is_hydra_installed, Hydra = pcall(require, 'hydra')
if is_hydra_installed then

  local cmd = require('hydra.keymap-util').cmd
  local maven_hint = [[
     aven
    ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────    
       ^Project^             ^Module^               ^File^                            ^Execute^                   ^Toggle^ 
        %{project}           
    ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────    
    _pc_: clean            _mc_: clean              _fr_: run                          _h_: from history            _tc_:  [%{tc}] clean
    _pp_: package          _mp_: package          _fstc_: surefire test                _s_: from project settings   _tt_:  [%{tt}] skip tests
    _pi_: install          _mi_: install          _fftc_: failsafe test                _v_: version set             _te_:  [%{te}] errors 
    _po_: edit pom         _mo_: edit pom         _fstm_: surefire test method                                    ^^_to_:  [%{to}] offline
                        ^^_mrf_: resume from      _fftm_: failsafe test method                                    ^^_tp_:  profiles [ %{tp} ]
                        ^^_mai_: also install
    
   ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────    
   _pd_: debug             _md_: debug              _fd_: debug file
  _psd_: surfire debug    _msd_: surefire debug   _fsdc_: debug surefire test class
  _pfd_: failsafe debug   _mfd_: failsafe debug   _ffdc_: debug failsafe test class
                                              ^^^^_fsdm_: debug surefire test method
                                              ^^^^_ffdm_: debug failsafe test method
  [_q_]: 
        ]]
  Hydra({
    name = 'Maven',
    hint = maven_hint,
    config = {
      buffer = bufnr,
      color = 'red',
      invoke_on_body = true,
      on_enter = function()
       M.settings = project.load_project_settings('maven', M.default_settings)
      end,
      hint = {
        border = 'rounded',
        funcs = {
          project = function() return M.get_project_name() or 'not found' end,
          tc = function() if M.settings.clean then return '  ' else return '   ' end end,
          tt = function() if M.settings.skip_tests then return '  ' else return '   ' end end,
          te = function() if M.settings.errors then return '  ' else return '   ' end end,
          to = function() if M.settings.offline then return '  ' else return '   ' end end,
          tp = function() return M.settings.profile or 'default' end,
        }
      },
    },
    mode = {'n','x'},
    body = '<leader>tm',
    heads = {
      { 'pc', cmd 'MavenProjectClean', { exit = true, nowait = true, desc = 'exit' } },
      { 'pp', cmd 'MavenProjectPackage', { exit = true, nowait = true, desc = 'exit' } },
      { 'pi', cmd 'MavenProjectInstall', { exit = true, nowait = true, desc = 'exit' } },
      { 'po', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'pd', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'psd', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'pfd', nil, { exit = true, nowait = true, desc = 'exit' } },

      { 'mc', cmd 'MavenModuleClean', { exit = true, nowait = true, desc = 'exit' } },
      { 'mp', cmd 'MavenModulePackage', { exit = true, nowait = true, desc = 'exit' } },
      { 'mi', cmd 'MavenModuleInstall', { exit = true, nowait = true, desc = 'exit' } },
      { 'mo', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'mrf', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'mai', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'md', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'msd', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'mfd', nil, { exit = true, nowait = true, desc = 'exit' } },


      { 'fr', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'fstc', cmd 'MavenSureFireTestClass', { exit = true, nowait = true, desc = 'test class' } },
      { 'fstm', cmd 'MavenSureFireTestMethod', { exit = true, nowait = true, desc = 'test method' } },
      { 'fftc', cmd 'MavneFailSafeTestClass', { exit = true, nowait = true, desc = 'integration test class' } },
      { 'fftm', cmd 'MavenFailSafeTestMethod', { exit = true, nowait = true, desc = 'integration test method' } },

      { 'fd', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'fsdc', cmd 'MavenSureFireDebugClass', { exit = true, nowait = true, desc = 'debug test class' } },
      { 'fsdm', cmd 'MavenSureFireDebugMethod', { exit = true, nowait = true, desc = 'debug test method' } },
      { 'ffdc', cmd 'MavneFailSafeDebugClass', { exit = true, nowait = true, desc = 'debug integration test class' } },
      { 'ffdm', cmd 'MavenFailSafeDebugMethod', { exit = true, nowait = true, desc = 'debug integration test method' } },

      { 'h', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 's', nil, { exit = true, nowait = true, desc = 'exit' } },
      { 'v', nil, { exit = true, nowait = true, desc = 'exit' } },


      { 'tt', cmd 'MavenToggleSkipTests', { exit = false, nowait = true, desc = 'toggle skip testes' } },
      { 'tc', cmd 'MavenToggleClean', { exit = false, nowait = true, desc = 'toggle clean' } },
      { 'te', cmd 'MavenToggleErrors', { exit = false, nowait = true, desc = 'toggle errors' } },
      { 'to', cmd 'MavenToggleOffline', { exit = false, nowait = true, desc = 'toggle offline' } },
      { 'tp', cmd 'MavenSetProfile', { exit = true, nowait = true, desc = 'select profie' } },

      { 'q', nil, { exit = true, nowait = true, desc = 'exit' } },
    }
  })
end


return M;
