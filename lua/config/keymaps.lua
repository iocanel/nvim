--
-- [[ General ]]
--
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--
-- [[ Open ]]
--
local telescope = require('telescope.builtin')
local themes = require('telescope.themes')
vim.keymap.set('n', '<leader>of', function() telescope.find_files(themes.get_ivy()) end, { desc = 'open files' })
vim.keymap.set('n', '<leader><space>', function() telescope.find_files(themes.get_ivy()) end, { desc = 'open files' })
vim.keymap.set('n', '<leader>ob', function() telescope.buffers(themes.get_ivy()) end, { desc = 'open buffer' })
vim.keymap.set('n', '<leader>or', function() telescope.oldfiles(themes.get_ivy()) end, { desc = 'open recent' })
vim.keymap.set('n', '<leader>oR', '<cmd>Telescope Repo<cr>', { desc = 'open repository' })
-- Zoxide
vim.keymap.set('n', '<leader>od', "<cmd>Telescope zoxide list<cr>", { desc = 'open directory' })
-- ToggleTerm
vim.keymap.set('n', '<leader>oc', "<cmd>ToggleTerm<cr>", { desc = 'open command line' })
vim.keymap.set('n', '<leader>ot', "<cmd>Neotree<cr>", { desc = 'open tree' })

vim.keymap.set('n', '<leader>.', "<cmd>Telescope resume<cr>", { desc = 'resume' })

--
-- [[ Toggle ]]
--
vim.keymap.set('n', '<leader>tt', "<cmd>Neotree toggle<cr>", { desc = 'toggle tree' })
vim.keymap.set('n', '<leader>tu', "<cmd>Telescope undo<cr>", { desc = 'toggle undo tree' })
-- [[ Template ]]
vim.keymap.set('n', '<leader>ts', "<cmd>TemplateSelect<cr>", { desc = 'template select' })

--
-- [[ Search ]]
--
vim.keymap.set('n', '<leader>sf', "<cmd>Telescope find_files<cr>", { desc = 'search files' })
vim.keymap.set('n', '<leader>sh', "<cmd>Telescope help_tags<cr>", { desc = 'search help' })
vim.keymap.set('n', '<leader>sw', "<cmd>Telescope grep_string<cr>", { desc = 'search current word' })
vim.keymap.set('n', '<leader>sg', "<cmd>Telescope live_grep<cr>", { desc = 'search grep' })
vim.keymap.set('n', '<leader>sd', "<cmd>Telescope diagnostics<cr>", { desc = 'search diagnostics' })
vim.keymap.set('n', '<leader>sb', function()
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = 'search buffer' })

--
-- [[ Window ]]
--
vim.keymap.set('n', '<leader>wsh', "<cmd>horizontal split<cr>", { desc = 'window split horizontally' })
vim.keymap.set('n', '<leader>wsv', "<cmd>vertical split<cr>", { desc = 'window split vertically' })
vim.keymap.set('n', '<leader>wjh', "<C-w>h", { desc = 'window jump horizontally' })
vim.keymap.set('n', '<leader>wjv', "<C-w>v", { desc = 'window jump vertically' })
vim.keymap.set('n', '<leader>wc', "<cmd>q<cr>", { desc = 'window close' })
vim.keymap.set('n', '<leader>wbk', "<cmd>q|bd<cr>", { desc = 'window and buffer kill' })
vim.keymap.set('n', '<C-x>k', "<cmd>q|bd<cr>", { desc = 'window and buffer kill' })


local winpick_installed, winpick = pcall(require, 'winpick')
if winpick_installed then
  vim.keymap.set('n', '<leader>wp', function()
  local winid = winpick.select()
   if winid then
  	vim.api.nvim_set_current_win(winid)
   end
  end, { desc = 'window pick' })
end



--
-- [[ Git ]]
--
vim.keymap.set('n', '<leader>gc', "<cmd>Git commit<cr>", { desc = 'git commit' })
-- Gitsigns
vim.keymap.set('n', '<leader>gs', "<cmd>Gitsigns stage_buffer<cr>", { desc = 'git stage buffer' })
vim.keymap.set('n', '<leader>ghn', "<cmd>Gitsigns next_hunk<cr>", { desc = 'git hunk pext' })
vim.keymap.set('n', '<leader>ghp', "<cmd>Gitsigns prev_hunk<cr>", { desc = 'git hunk previous' })
vim.keymap.set('n', '<leader>ghs', "<cmd>Gitsigns stage_hunk<cr>", { desc = 'git hunk stage' })
vim.keymap.set('n', '<leader>ghu', "<cmd>Gitsigns undo_stage_hunk<cr>", { desc = 'git hunk uundo stage' })
vim.keymap.set('n', '<leader>ghr', "<cmd>Gitsigns reset_hunk<cr>", { desc = 'git hunk reset' })
vim.keymap.set('n', '<leader>ghv', "<cmd>Gitsigns preview_hunk<cr>", { desc = 'git hunk preview' })
-- Neogit
vim.keymap.set('n', '<leader>gn', "<cmd>Neogit<cr>", { desc = 'neogit' })
vim.keymap.set('n', '<leader>gg', "<cmd>Neogit<cr>", { desc = 'neogit' })
vim.keymap.set('n', '<leader>gt', "<cmd>Tardis git<cr>", { desc = 'git timemachine' })
vim.keymap.set('n', '<leader>gO', "<cmd>Octo<cr>", { desc = 'Octo' })

-- Octo PR commands
vim.keymap.set('n', '<leader>gopl', "<cmd>Octo pr list<cr>", { desc = 'list pull requests' })
vim.keymap.set('n', '<leader>gopc', "<cmd>Octo pr checkout<cr>", { desc = 'checkout pull request' })
vim.keymap.set('n', '<leader>gopm', "<cmd>Octo pr merge<cr>", { desc = 'merge pull request' })
vim.keymap.set('n', '<leader>gopd', "<cmd>Octo pr diff<cr>", { desc = 'show pr diff' })
vim.keymap.set('n', '<leader>gopR', "<cmd>Octo pr reload<cr>", { desc = 'reload pull request' })
vim.keymap.set('n', '<leader>gopb', "<cmd>Octo pr browser<cr>", { desc = 'open in browser' })

-- Octo PR review commands
vim.keymap.set('n', '<leader>goprs', "<cmd>OctoReviewStartOrSubmit<cr>", { desc = 'review start or submit' })
vim.keymap.set('n', '<leader>goprc', "<cmd>Octo review close<cr>", { desc = 'close review' })
vim.keymap.set('n', '<leader>goprd', "<cmd>Octo review discard<cr>", { desc = 'discard review' })

-- Octo issue commands
vim.keymap.set('n', '<leader>goil', "<cmd>Octo issues list<cr>", { desc = 'list issues' })
vim.keymap.set('n', '<leader>goic', "<cmd>Octo issue close<cr>", { desc = 'close issue' })
vim.keymap.set('n', '<leader>goiR', "<cmd>Octo issue reload<cr>", { desc = 'reload issue' })
vim.keymap.set('n', '<leader>goib', "<cmd>Octo issue browser<cr>", { desc = 'issue browser' })

-- Octo reaction commands
vim.keymap.set('n', '<leader>goru', "<cmd>Octo reaction thumbs_up<cr>", { desc = 'reaction thumbs up' })
vim.keymap.set('n', '<leader>gord', "<cmd>Octo reaction thumbs_down<cr>", { desc = 'reaction thumbs down' })
vim.keymap.set('n', '<leader>gort', "<cmd>Octo reaction tada<cr>", { desc = 'reaction tada' })
vim.keymap.set('n', '<leader>gorh', "<cmd>Octo reaction heart<cr>", { desc = 'reaction heart' })
vim.keymap.set('n', '<leader>gorr', "<cmd>Octo reaction rocket<cr>", { desc = 'reaction rocket' })
vim.keymap.set('n', '<leader>gorp', "<cmd>Octo reaction party<cr>", { desc = 'reaction party' })

-- Octo general commands
vim.keymap.set('n', '<leader>goa', "<cmd>Octo actions<cr>", { desc = 'octo actions' })

--
-- [[ Editor ]]
--
local editor = require("config.editor")
vim.keymap.set('n', '<leader>es', editor.statusline_toggle, { desc = 'status line toggle' })
vim.keymap.set('n', '<leader>en', editor.linenumber_toggle, { desc = 'line number toggle' })
vim.keymap.set('n', '<leader>ef', editor.focus_toggle, { desc = 'focus mode toggle' })

--
-- [[ Debug ]]
--
local dap_java = require("config.dap.java")
local dapui = require("dapui")
vim.keymap.set('n', '<leader>dd', "<cmd>DebugDwim<cr>", {desc = "debug dwim"})
vim.keymap.set('n', '<leader>dq', "<cmd>DapCloseAll<cr>", {desc = "debug close all"})
vim.keymap.set('n', '<leader>da', dap_java.attach_to_remote, {desc = "debug remote"})
vim.keymap.set('n', '<leader>di', "<cmd>DapStepIn<cr>", {desc = "dap step in"})
vim.keymap.set('n', '<leader>do', "<cmd>DapStepOver<cr>", {desc = "dap step over"})
vim.keymap.set('n', '<leader>dO', "<cmd>DapStepOut<cr>", {desc = "dap step out"})
vim.keymap.set('n', '<leader>dc', "<cmd>DapContinue<cr>", {desc = "dap continue"})
vim.keymap.set('n', '<leader>db', "<cmd>DapToggleBreakpoint<cr>", {desc = "dap toggle breakpoint"})
vim.keymap.set('n', '<leader>dr', "<cmd>DapToggleRepl<cr>", {desc = "dap toggle repl"})

-- Debug-specific arrow key mappings (only active during debug sessions)
local debug_mappings_set = false

local function set_debug_mappings()
  if debug_mappings_set then return end
  vim.keymap.set('n', '<Down>', "<cmd>DapStepInto<cr>", { desc = 'Debug: Step into' })
  vim.keymap.set('n', '<Up>', "<cmd>DapStepOver<cr>", { desc = 'Debug: Step over' })
  vim.keymap.set('n', '<Left>', "<cmd>DapStepOut<cr>", { desc = 'Debug: Step out' })
  vim.keymap.set('n', '<Right>', "<cmd>DapContinue<cr>", { desc = 'Debug: Continue' })
  debug_mappings_set = true
end

local function unset_debug_mappings()
  if not debug_mappings_set then return end
  pcall(vim.keymap.del, 'n', '<Down>')
  pcall(vim.keymap.del, 'n', '<Up>')
  pcall(vim.keymap.del, 'n', '<Left>')
  pcall(vim.keymap.del, 'n', '<Right>')
  debug_mappings_set = false
end

-- Set up DAP event listeners to enable/disable arrow keys during debug sessions
local dap = require('dap')
dap.listeners.after.event_initialized["debug_arrows"] = set_debug_mappings
dap.listeners.before.event_terminated["debug_arrows"] = unset_debug_mappings
dap.listeners.before.disconnect["debug_arrows"] = unset_debug_mappings
vim.keymap.set('n', '<leader>dut', function()dapui.toggle('tray')end, {desc = "dap ui toggle"})
vim.keymap.set('n', '<leader>dus', function()dapui.toggle('sidebar')end, {desc = "dap ui toggle"})
vim.keymap.set('n', '<leader>dui', dapui.toggle, {desc = "dap ui toggle"})

--
-- [[ Diagnostic keymaps ]]
--
vim.keymap.set('n', '<leader>Dp', vim.diagnostic.goto_prev, {desc = "go to previous"})
vim.keymap.set('n', '<leader>Dn', vim.diagnostic.goto_next, {desc = "go to next"})
vim.keymap.set('n', '<leader>Df', vim.diagnostic.open_float, {desc = "open float"})
vim.keymap.set('n', '<leader>Ds', vim.diagnostic.setloclist, {desc = "add to location list"})

--
-- [[Hop]]
--
local hop_installed, hop = pcall(require, 'hop');
if hop_installed then
  local directions = require('hop.hint').HintDirection
  vim.keymap.set('n', '<leader>ha', function() hop.hint_anywhere() end, {remap=true})
  vim.keymap.set('n', '<leader>hw', function() hop.hint_words() end, {remap=true})
  vim.keymap.set('n', '<leader>hf', function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false }) end, {remap=true})
  vim.keymap.set('n', '<leader>hF', function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false }) end, {remap=true})
  vim.keymap.set('n', '<leader>ht', function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 }) end, {remap=true})
  vim.keymap.set('n', '<leader>hT', function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 }) end, {remap=true})
end



--
-- [[ Copilot ]]
--
vim.keymap.set('n', '<leader>cpc', '<cmd>CopilotChat<cr>', {desc = "copilot chat"})
vim.keymap.set('n', '<leader>cpf', '<cmd>CopilotChatFix<cr>', {desc = "copilot fix"})
vim.keymap.set('n', '<leader>cpe', '<cmd>CopilotChatFix<cr>', {desc = "copilot explain"})


--
-- [Codeium]
--
vim.keymap.set('n', '<leader>ca', function()
  return vim.fn['codeium#Accept']()
end, {desc = "codeium accept"})

vim.keymap.set('n', '<leader>cn', function()
  return vim.fn['codeium#CycleCompletions'](1)
end, {desc = "codeium next"})

vim.keymap.set('n', '<leader>cp', function()
  return vim.fn['codeium#CycleCompletions'](-1)
end, {desc = "codeium previous"})

vim.keymap.set('n', '<leader>tmci', function()
  local mvn = require('config.mvn')
  mvn.clean_install()
end, { desc = 'mvn clean install' })

--
-- [[ LSP ]]
--
function setup_lsp_bindings()
  vim.keymap.set('n', '<leader>lrn', vim.lsp.buf.rename, { desc = 'rename'})
  vim.keymap.set('n', '<leader>lca', vim.lsp.buf.code_action, { desc = 'code action'})

  vim.keymap.set('n', '<leader>lgd', vim.lsp.buf.definition, { desc = 'goto definition'})
  vim.keymap.set('n', '<leader>lgr', function()telescope.lsp_references(themes.get_ivy()) end, { desc = 'goto references'})
  vim.keymap.set('n', '<leader>lgi', vim.lsp.buf.implementation, { desc = 'goto implementation'})
  vim.keymap.set('n', '<leader>ltd', vim.lsp.buf.type_definition, { desc = 'type definition'})
  vim.keymap.set('n', '<leader>lsd', require('telescope.builtin').lsp_document_symbols, { desc = 'document symbols'})
  vim.keymap.set('n', '<leader>lsw', require('telescope.builtin').lsp_dynamic_workspace_symbols, { desc = 'workspace symbols'})
  vim.keymap.set('n', '<leader>lgb', require('config.navigation').go_back, { desc = 'goto back'})
  vim.keymap.set('n', '<leader>lgf', require('config.navigation').go_forward, { desc = 'goto forward'})
  vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, { desc = 'format buffer'})
end

function setup_coc_bindings()
  vim.keymap.set('n', '<leader>lrn', '<Plug>(coc-refactor)', { desc = 'rename'})
  vim.keymap.set('x', '<leader>lrn', '<Plug>(coc-refactor-selected)', { desc = 'rename'})
  vim.keymap.set('n', '<leader>lca', '<Plug>(coc-codeaction)', { desc = 'code action'})
  vim.keymap.set('x', '<leader>lca', '<Plug>(coc-codeaction-selected)', { desc = 'code action'})

  vim.keymap.set('n', '<leader>lgd', '<Plug>(coc-definition)', { desc = 'goto definition'})
  vim.keymap.set('n', '<leader>lgr', '<Plug>(coc-references)', { desc = 'goto references'})
  vim.keymap.set('n', '<leader>lgi', '<Plug>(coc-implementation)', { desc = 'goto implementation'})
  vim.keymap.set('n', '<leader>ltd', '<Plug>(coc-type-definition)', { desc = 'type definition'})
end

-- See `:help K` for why this keymap
vim.keymap.set('n', '<leader>ldh', vim.lsp.buf.hover, { desc = 'hover documentation'})
vim.keymap.set('n', '<leader>lds', vim.lsp.buf.signature_help, { desc = 'signature documentation'})

-- Lesser used LSP functionality
vim.keymap.set('n', '<leader>lgD', vim.lsp.buf.declaration, { desc = 'goto declaration'})
vim.keymap.set('n', '<leader>lwa', vim.lsp.buf.add_workspace_folder, { desc = 'workspace add folder'})
vim.keymap.set('n', '<leader>lwr', vim.lsp.buf.remove_workspace_folder, { desc = 'workspace remove folder'})
vim.keymap.set('n', '<leader>lwl', function()
  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, { desc = 'workspace list folders'})


--
-- JDTLS
--

vim.keymap.set('n', '<leader>jtg', function() require("jdtls.tests").generate() end , { desc = 'generate tests'})
vim.keymap.set('n', '<leader>jtj', function() require("jdtls.tests").generate() end , { desc = 'goto test or subjects'})



setup_lsp_bindings()

-- [Optional] use coc bindings for .java files if coc-java is installed
local coc_installed, _ = pcall(require, 'coc-java')
if coc_installed then
  vim.cmd('autocmd FileType java lua setup_coc_bindings()')
end
