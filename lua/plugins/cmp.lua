return {
   {
    'hrsh7th/nvim-cmp',
    commit = "11a95792a5be0f5a40bab5fc5b670e5b1399a939",
    dependencies = { 
  		"hrsh7th/cmp-nvim-lsp",
  		"hrsh7th/cmp-nvim-lua",
  		"hrsh7th/cmp-buffer",
  		"hrsh7th/cmp-path",
  		"hrsh7th/cmp-cmdline",
  		"saadparwaiz1/cmp_luasnip",
  		"L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
        end, { 'i', 's' }),
      },
      sources = {
        { name = 'nvim_lsp' },
        { name = 'nvim_lua' },
        { name = 'luasnip' },
      },
      })
    end
  }
}
