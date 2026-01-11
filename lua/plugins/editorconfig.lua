return {
  {
    'editorconfig/editorconfig-vim',
    lazy = false,
    init = function()
      -- Ensure EditorConfig works with fugitive and other Git plugins
      vim.g.EditorConfig_exclude_patterns = {'fugitive://.*', 'scp://.*'}
      
      -- Enable verbose mode for debugging (optional)
      -- vim.g.EditorConfig_verbose = 1
      
      -- Disable EditorConfig for certain file types if needed
      -- vim.g.EditorConfig_disable_rules = {'trim_trailing_whitespace'}
      
      -- Disable max_line_length rule to prevent colorcolumn
      vim.g.EditorConfig_disable_rules = {'max_line_length'}
    end,
    config = function()
      -- EditorConfig plugin is mostly configuration-driven through .editorconfig files
      -- The plugin automatically applies settings when files are opened
      
      -- Ensure EditorConfig settings are applied after LSP attachment
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          -- Re-apply EditorConfig settings after LSP attaches
          vim.cmd("EditorConfigReload")
          
          -- Ensure LSP formatters respect EditorConfig indentation
          vim.api.nvim_buf_create_user_command(bufnr, 'FormatWithEditorConfig', function()
            -- Apply EditorConfig before formatting
            vim.cmd("EditorConfigReload")
            vim.lsp.buf.format({ bufnr = bufnr })
          end, { desc = 'Format with EditorConfig settings' })
        end
      })
      
      -- Optional: Add custom handling for specific properties
      vim.api.nvim_create_autocmd("User", {
        pattern = "EditorConfigReload", 
        callback = function()
          -- Custom logic when EditorConfig is reloaded
          -- This can be useful for applying additional formatting rules
        end
      })
    end
  }
}