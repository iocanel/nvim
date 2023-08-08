return {
  {
    'glepnir/template.nvim',
    commit = '0b9a02148fd2b7832f801e5ebb40684d4eea4ead',
    opts = {
      temp_dir = '/home/iocanel/.config/nvim/templates/',
      author = "Ioannis Canellos",
      email = "iocanel@gmail.com"
    },
    init = function()
    -- Register extension for telescope
    require("telescope").load_extension('find_template')

    -- Java templates
    vim.cmd('autocmd BufNewFile *.java :Template main')
    vim.cmd('autocmd BufNewFile *.html :Template index')
    end
  } 
}
