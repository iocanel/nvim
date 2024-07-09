local M = {
};

-- Define the custom indentation function
function M:indent(lnum)
  print("Indenting line " .. lnum)
  local prev_lnum = vim.fn.prevnonblank(lnum - 1)
  if prev_lnum == 0 then
    return -1
  end

  local prev_line = vim.fn.getline(prev_lnum)

  if prev_line:match("withNew%w+") or prev_line:match("addNew%w+") then
    return vim.fn.indent(prev_lnum) + vim.o.shiftwidth
  elseif prev_line:match("end%w+") then
    return vim.fn.indent(prev_lnum) - vim.o.shiftwidth
  else
    return -1
  end
end

return M;
