return {
  {
    'pwntester/octo.nvim',
    commit = '22328c578bc013fa4b0cef3d00af35efe0c0f256',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = function ()
      require"octo".setup()
    end
  }
}
