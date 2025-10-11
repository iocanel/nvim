
local function jdtls_setup_standalone_project()
    -- Get the directory of the current file
    local file_dir = vim.fn.expand("%:p:h")

    -- Define file paths
    local classpath_file = file_dir .. "/.classpath"
    local settings_dir = file_dir .. "/.settings"
    local prefs_file = settings_dir .. "/org.eclipse.jdt.core.prefs"

    -- Ensure .settings directory exists
    vim.fn.mkdir(settings_dir, "p")

    -- Write or update .classpath
    local classpath_content = [[
<?xml version="1.0" encoding="UTF-8"?>
<classpath>
    <classpathentry kind="src" path="."/>
</classpath>
]]
    local classpath_fd = io.open(classpath_file, "w")
    if classpath_fd then
        classpath_fd:write(classpath_content)
        classpath_fd:close()
    end

    -- Write or update org.eclipse.jdt.core.prefs
    local prefs_content = [[
eclipse.preferences.version=1
org.eclipse.jdt.core.compiler.problem.enablePreviewFeatures=enabled
]]
    local prefs_fd = io.open(prefs_file, "w")
    if prefs_fd then
        prefs_fd:write(prefs_content)
        prefs_fd:close()
    end

    -- Reload JDT LS configuration
    local clients = vim.lsp.get_clients()
    for _, client in ipairs(clients) do
        if client.name == "jdtls" then
            print("Restarting jdtls...")
            vim.cmd("JdtWipeDataAndRestart")
            break
        end
    end
end

local function jpa_list_entities()
    local entities = {}
    local grep_cmd = "rg --no-heading --with-filename --only-matching '@Entity' --glob '*.java'"
    local handle = io.popen(grep_cmd)

    if handle then
        for line in handle:lines() do
            local filename = line:match("^(.-):")
            local class_name = nil

            -- Open file and extract the class name
            if filename then
                for file_line in io.lines(filename) do
                    class_name = file_line:match("class%s+(%w+)")
                    if class_name then break end
                end
            end

            if filename and class_name then
                table.insert(entities, { file = filename, class = class_name })
            end
        end
        handle:close()
    end

    return entities
end

--- 📌 Generic function that selects a JPA entity and applies an action
local function do_with_jpa_entity(action)
    local has_telescope, telescope = pcall(require, "telescope.pickers")
    if not has_telescope then
        print("Telescope not found!")
        return
    end

    local finders = require("telescope.finders")
    local sorters = require("telescope.sorters")
    local actions = require("telescope.actions")
    local previewers = require("telescope.previewers")
    local action_state = require("telescope.actions.state")

    local entities = jpa_list_entities()
    if #entities == 0 then
        print("No @Entity classes found!")
        return
    end

    telescope.new({
        prompt_title = "Select a JPA Entity",
        finder = finders.new_table({
            results = entities,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.class .. " (" .. entry.file .. ")",
                    ordinal = entry.class
                }
            end
        }),
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                local bufnr = self.state.bufnr
                local file_path = entry.value  -- Ensure this is a string

                -- Debugging: Check if file_path is valid
                if type(file_path) ~= "string" or file_path == "" then
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Invalid file path!" })
                    return
                end

                -- Ensure the file exists
                if vim.fn.filereadable(file_path) == 0 then
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "File not found: " .. file_path })
                    return
                end

                -- Read file content safely
                local file_content = vim.fn.readfile(file_path)

                -- Debugging: Check if the result is actually a list
                if type(file_content) ~= "table" then
                    file_content = { "Error: Could not read file content." }
                end

                -- Set syntax highlighting and load file contents
                vim.api.nvim_buf_set_option(bufnr, "filetype", "java")
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, file_content)
            end
        }),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection and action then
                    action(selection.value)
                end
            end)
            return true
        end,
    }):find()
end

--- 📌 Function to Open a Selected JPA Entity
local function open_jpa_entity(selected_entity)
    vim.cmd("edit " .. selected_entity.file)
end


local function generate_dto(selected_entity)
    local entity_file = selected_entity.file
    local class_name = selected_entity.class
    local dto_name = class_name .. "Dto"

    -- Extract directory and generate DTO path
    local dto_file = entity_file:gsub("(%w+).java$", dto_name .. ".java")

    -- Read package from entity file
    local package_line = ""
    local entity_imports = {}
    local fields = {}

    -- Scan file for package, imports, and fields
    for line in io.lines(entity_file) do
        -- Capture package
        local pkg = line:match("^package%s+([%w%.]+);")
        if pkg then
            package_line = "package " .. pkg .. ";\n\n"
        end

        -- Capture imports
        local import_stmt = line:match("^import%s+([%w%.]+);")
        if import_stmt then
            table.insert(entity_imports, import_stmt)
        end

        -- Match private and public fields, unwrap Optional<T>
        local p_type, p_name = line:match("private%s+([%w<>%[%]_%.]+)%s+([%w_]+)%s*;")
        local pub_type, pub_name = line:match("public%s+([%w<>%[%]_%.]+)%s+([%w_]+)%s*;")

        local field_type = p_type or pub_type
        local field_name = p_name or pub_name

        -- Unwrap Optional<T> (convert "Optional<T>" to "T")
        if field_type and field_name then
            local unwrapped_type = field_type:gsub("Optional<", ""):gsub(">", "")
            table.insert(fields, { type = unwrapped_type, name = field_name })
        end
    end

    -- Check if any fields were found
    if #fields == 0 then
        print("⚠️ No fields found in entity: " .. class_name)
        return
    end

    -- Identify required imports (only copy imports relevant to fields)
    local required_imports = {}
    for _, field in ipairs(fields) do
        for _, import_stmt in ipairs(entity_imports) do
            -- Extract class name from import (last part after ".")
            local imported_class = import_stmt:match("([%w_]+)$")
            -- If the field type matches the imported class, keep the import
            if imported_class and field.type:match(imported_class) then
                required_imports[import_stmt] = true
            end
        end
    end

    -- Remove unnecessary Optional import
    required_imports["java.util.Optional"] = nil

    -- Generate import statements
    local import_statements = ""
    for imp in pairs(required_imports) do
        import_statements = import_statements .. "import " .. imp .. ";\n"
    end
    if import_statements ~= "" then
        import_statements = import_statements .. "\n"
    end

    -- Generate record DTO content
    local dto_content = package_line .. import_statements
    dto_content = dto_content .. "public record " .. dto_name .. "("
    for i, field in ipairs(fields) do
        dto_content = dto_content .. field.type .. " " .. field.name
        if i < #fields then
            dto_content = dto_content .. ", "
        end
    end
    dto_content = dto_content .. ") {}"

    -- Write to file
    local file = io.open(dto_file, "w")
    if file then
        file:write(dto_content)
        file:close()
        print("✅ DTO created: " .. dto_file)

        -- Open the newly created DTO in Neovim
        vim.cmd("edit " .. dto_file)
    else
        print("❌ Failed to write DTO file")
    end
end

local function debug_test_class()
  local jdtls = require("jdtls")

  -- Ensure jdtls is available
  if not jdtls or not jdtls.test_class then
    vim.notify("jdtls is not available or test_class function not found. Ensure jdtls is properly configured with test bundles.", vim.log.levels.ERROR)
    return
  end

  -- Get current file info to verify it's a Java file
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("%.java$") then
    vim.notify("Current buffer is not a Java file", vim.log.levels.ERROR)
    return
  end

  print("Debugging test class...")
  jdtls.test_class()
end

local function debug_test_method()
  local jdtls = require("jdtls")

  -- Ensure jdtls is available
  if not jdtls or not jdtls.test_nearest_method then
    vim.notify("jdtls is not available or test_nearest_method function not found. Ensure jdtls is properly configured with test bundles.", vim.log.levels.ERROR)
    return
  end

  -- Get current file info to verify it's a Java file
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("%.java$") then
    vim.notify("Current buffer is not a Java file", vim.log.levels.ERROR)
    return
  end

  print("Debugging nearest test method...")
  jdtls.test_nearest_method()
end

-- 📌 Create Neovim commands
vim.api.nvim_create_user_command("JdtStandalone", jdtls_setup_standalone_project, {})
vim.api.nvim_create_user_command("JpaOpenEntity", function() do_with_jpa_entity(open_jpa_entity) end, {})
vim.api.nvim_create_user_command("JpaGenerateDto", function() do_with_jpa_entity(generate_dto) end, {})
vim.api.nvim_create_user_command("JavaDebugTestClass", debug_test_class, {})
vim.api.nvim_create_user_command("JavaDebugTestMethod", debug_test_method, {})
