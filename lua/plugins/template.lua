return {
  {
    'glepnir/template.nvim',
    commit = '0b9a02148fd2b7832f801e5ebb40684d4eea4ead',
    config = function()
      require('template').setup({
        temp_dir = '/home/iocanel/.config/nvim/templates/',
        author = "Ioannis Canellos",
        email = "iocanel@gmail.com",
      })
    end,
    init = function()
      local telescope = require("telescope.builtin")
      local previewers = require("telescope.previewers")
      local actions = require("telescope.actions")
      local actions_state = require("telescope.actions.state")
      local scan = require("plenary.scandir")

      -- Register extension for telescope
      require("telescope").load_extension('find_template')

      -- Java templates
      vim.cmd('autocmd BufNewFile *.java :Template main')
      vim.cmd('autocmd BufNewFile *.html :Template index')
      vim.cmd('autocmd BufNewFile *.sol :Template main')
      vim.cmd('autocmd BufNewFile *.nix :Template main')
      vim.cmd('autocmd BufNewFile *.vue :Template main')

      vim.api.nvim_create_autocmd("BufNewFile", {
        pattern = "*.go",
        callback = function(args)
          local fname = vim.fn.fnamemodify(args.file, ":t")
          local template

          if fname:match("_test%.go$") then
            template = "main_test"
          else
            template = "main"
          end

          -- Run the template command if it exists
          vim.cmd("silent! Template " .. template)
        end,
      })

      -- Function to select templates using Telescope
      local function select_template()
        local filetype = vim.bo.filetype
        local template_dir = "/home/iocanel/.config/nvim/templates/" .. filetype .. "/"

        -- Ensure template directory exists
        if vim.fn.isdirectory(template_dir) == 0 then
          vim.notify("No templates found for filetype: " .. filetype, vim.log.levels.WARN)
          return
        end

        -- Scan for all files in the template directory
        local templates = scan.scan_dir(template_dir, { hidden = false, depth = 1 })

        -- Extract only template names without extensions
        local filtered_templates = {}
        for _, file in ipairs(templates) do
          local filename = vim.fn.fnamemodify(file, ":t:r") -- Get filename without extension
          table.insert(filtered_templates, { name = filename, path = file })
        end

        -- If no templates are found, notify the user
        if #filtered_templates == 0 then
          vim.notify("No templates available for " .. filetype, vim.log.levels.WARN)
          return
        end

        -- Use Telescope to display the filtered templates
        require("telescope.pickers").new({}, {
          prompt_title = "Select Template",
          finder = require("telescope.finders").new_table({
            results = filtered_templates,
            entry_maker = function(entry)
              return {
                value = entry.path,
                display = entry.name,
                ordinal = entry.name,
                path = entry.path,
              }
            end,
          }),
          sorter = require("telescope.config").values.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            map("i", "<CR>", function()
              local selection = actions_state.get_selected_entry()
              if selection then
                actions.close(prompt_bufnr)
                -- Apply the template correctly to the current file path
                vim.cmd("Template " .. vim.fn.fnamemodify(selection.value, ":t:r"))
              end
            end)
            return true
          end,
          previewer = previewers.new_buffer_previewer({
            title = "Template Preview",
            define_preview = function(self, entry)
              if entry and entry.path then
                local lines = vim.fn.readfile(entry.path)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
              end
            end,
          }),
        }):find()
      end

      -- Register the custom command
      vim.api.nvim_create_user_command("TemplateSelect", select_template, {})
    end
  }
}
