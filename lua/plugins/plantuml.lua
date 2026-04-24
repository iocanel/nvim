return {
  {
    "aklt/plantuml-syntax",
    ft = "plantuml",
    config = function()
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.puml", "*.plantuml", "*.pu", "*.uml", "*.iuml" },
        callback = function()
          local src = vim.fn.expand("%:p")
          local dir = vim.fn.expand("%:p:h")
          vim.fn.jobstart({ "plantuml", "-tsvg", "-o", dir, src }, {
            stderr_buffered = true,
            on_stderr = function(_, data)
              local msg = table.concat(data, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
              if msg ~= "" then
                vim.schedule(function()
                  vim.notify("PlantUML error:\n" .. msg, vim.log.levels.ERROR)
                end)
              end
            end,
            on_exit = function(_, code)
              if code == 0 then
                vim.schedule(function()
                  vim.notify("PlantUML: diagram updated", vim.log.levels.INFO)
                end)
              end
            end,
          })
        end,
      })
    end,
  },
}
