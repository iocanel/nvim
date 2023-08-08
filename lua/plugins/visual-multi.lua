-- Basic usage:

-- select words with Ctrl-N (like Ctrl-d in Sublime Text/VS Code)
-- create cursors vertically with Ctrl-Down/Ctrl-Up
-- press n/N to get next/previous occurrence
-- press [/] to select next/previous cursor
-- press q to skip current and get next occurrence
-- press Q to remove current cursor/selection
-- start insert mode with i,a,I,A
return {
  {
    'mg979/vim-visual-multi', 
    commit = '724bd53adfbaf32e129b001658b45d4c5c29ca1a',
  }
}
