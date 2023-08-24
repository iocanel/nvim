return {
  {
    'Exafunction/codeium.vim',
    event = 'BufEnter',
    config = function ()
      vim.keymap.set('i', '<C-c>a', function () return vim.fn['codeium#Accept']() end, { expr = true })
      vim.keymap.set('i', '<C-c>n', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true })
      vim.keymap.set('i', '<C-c>p', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true })
      vim.keymap.set('i', '<C-c>c', function() return vim.fn['codeium#Clear']() end, { expr = true })
    end
  }
}
