return {
  "xiyaowong/transparent.nvim",
  config = function()
    require("transparent").setup({
      groups = {
        "Normal", "NormalNC", "Comment", "Constant", "Special", "Identifier",
        "Statement", "PreProc", "Type", "Underlined", "Todo", "String", "Function",
        "Conditional", "Repeat", "Operator", "Structure", "LineNr", "NonText",
        "SignColumn", "CursorLineNr", "EndOfBuffer",
      },
      extra_groups = {},
      exclude_groups = {},
    })
  end,
}

--
-- Issues related to transparent.vim
--
--
-- Failed to run `config` for transparent.nvim                                                                                          
--                                                                                                                                      
-- ...re/nvim/lazy/transparent.nvim/lua/transparent/config.lua:21: opt: expected table, got string                                      
--                                                                                                                                      
-- # stacktrace:                                                                                                                        
--   - vim/shared.lua:0 _in_ **validate**                                                                                               
--   - /transparent.nvim/lua/transparent/config.lua:21 _in_ **setup**                                                                   
--   - .config/nvim/lua/plugins/transparent.lua:4 _in_ **config**                                                                       
--   - .config/nvim/lua/config/lazy.lua:12                                                                                              
--   - .dotfiles/neovim/.config/nvim/init.lua:4                                                                                         
-- Press ENTER or type command to continue    
--
-- 
--
--
-- Solution:
--
-- Edits -rf ~/.local/share/nvim/lazy/transparent.nvim and set
--
-- 
--    vim.validate {
--      opts = {opts, 'table'},
--      groups = {opts.groups, 'table', true},
--      extra_groups = {opts.extra_groups, 'table', true},
--      exclude_groups = {opts.exclude_groups, 'table', true},
--      on_clear = {opts.on_clear, 'function', true},
--    }
