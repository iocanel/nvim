
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
    local clients = vim.lsp.get_active_clients()
    for _, client in ipairs(clients) do
        if client.name == "jdtls" then
            print("Restarting jdtls...")
            vim.cmd("JdtWipeDataAndRestart")
            break
        end
    end
end

-- Create Neovim command
vim.api.nvim_create_user_command("JdtStandalone", jdtls_setup_standalone_project, {})
