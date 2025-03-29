-- [[ Setting options ]]
-- See `:help vim.o`

-- Make vim silent
--vim.o.silent = true -- no longer available after upgrading to latest version of neovim

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.ruler = false

-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

-- Set colorscheme
vim.o.termguicolors = true

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

vim.o.clipboard = 'unnamedplus'                  -- allows neovim to access the system clipboard
vim.o.cursorline = true
vim.o.relativenumber = true
vim.o.laststatus = 0
vim.o.showcmd = false
vim.o.showmode = false
-- Autoread file when changed
vim.o.autoread = true
vim.cmd [[
  autocmd CursorHold * checktime
]]
--

-- Indentation
--vim.o.autoident = true -- no longer available after upgrading to latest version of neovim
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2

-- Centralized logic to enable/disable spell checking based on file buffer type
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  callback = function()
    local file_types = { "asciidoc", "markdown", "org", "gitcommit", "text", "java", "go", "rust", "python" }

    -- Check if the buffer has an associated file and the file type matches
    if vim.fn.bufname('%') ~= '' and vim.tbl_contains(file_types, vim.bo.filetype) then
      vim.opt.spell = true
      vim.opt.spelllang = { 'en' }
    else
      vim.opt.spell = false
    end
  end,
})

-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '


-- [[ Additional Filetypes ]]
--
-- Function vim.filetype.match does not recognize all filetypes
-- This section manually registers needed filetypes
-- Source: https://www.reddit.com/r/neovim/comments/rvwsl3/introducing_filetypelua_and_a_call_for_help/
--
-- html
vim.filetype.add({
  extension = {
    html = "html"
  }
})
