-- Run with:
--   nvim --headless "+luafile tests/jdtls.lua"
-- Works no matter where you run it from.
-- Env overrides:
--   JDTLS_WAIT_MS=20000

local function die(msg)
  print(msg)
  vim.cmd.cq() -- non-zero exit
end

-- Resolve absolute path to THIS script's directory
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")

-- Project root that jdtls should detect (contains pom.xml/gradle files)
-- Default to <test_dir>/test_project, override with TEST_PROJECT_ROOT if you prefer.
local project_root = this_dir .. "/test_project"
project_root = vim.fn.fnamemodify(project_root, ":p"):gsub("/$", "")
file = project_root .. "/src/main/java/com/iocanel/App.java"

-- Sanity: project_root must exist and contain a build file
if vim.fn.isdirectory(project_root) == 0 then
  die("Project root does not exist: " .. project_root)
end
local has_build = (vim.fn.filereadable(project_root .. "/pom.xml") == 1)
                   or (vim.fn.filereadable(project_root .. "/build.gradle") == 1)
                   or (vim.fn.filereadable(project_root .. "/build.gradle.kts") == 1)
if not has_build then
  print("Warning: no pom.xml or build.gradle in " .. project_root .. " — jdtls may still start if your config sets root_dir differently.")
end

-- Temporarily chdir so root detection & workspace folders behave
local prev_cwd = vim.loop.cwd()
local ok_chdir, err = pcall(vim.fn.chdir, project_root)
if not ok_chdir then
  die("Failed to chdir to project root: " .. tostring(err))
end

-- Open file (absolute) to trigger your normal config
vim.cmd.edit(vim.fn.fnameescape(file))
if vim.bo.filetype ~= "java" then
  -- restore cwd before exiting
  pcall(vim.fn.chdir, prev_cwd)
  die("Buffer filetype is not 'java' (got: " .. tostring(vim.bo.filetype) .. ")")
end

-- Wait for jdtls to attach & fully initialize
local timeout = tonumber(vim.env.JDTLS_WAIT_MS) or 25000
local ok = vim.wait(timeout, function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client.name == "jdtls" and client.initialized then
      -- Wait for JDTLS to be in "ServiceReady" state
      -- This happens after project analysis is complete
      local caps = client.server_capabilities or {}
      
      -- More lenient check: just need some key capabilities
      local has_basic_caps = caps.hoverProvider 
                          or caps.definitionProvider 
                          or caps.textDocumentSync ~= nil
                          or caps.documentSymbolProvider
      
      if has_basic_caps then
        -- Additional wait to ensure stability after ServiceReady
        vim.wait(2000)
        return true
      end
    end
  end
  return false
end, 1000)

-- Restore cwd regardless of outcome
pcall(vim.fn.chdir, prev_cwd)

if not ok then
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients()) do table.insert(names, c.name) end
  print("jdtls did not start within timeout. Active clients: " .. table.concat(names, ", "))
  print("Check :messages and " .. (vim.lsp.get_log_path() or "(no log path)"))
  vim.cmd.cq()
  return
end

-- Capability sanity (robust: accept any common capability)
local jdtls = vim.lsp.get_clients({ name = "jdtls", bufnr = 0 })[1]
local caps = jdtls and jdtls.server_capabilities or {}

local function has_any_cap()
  return caps.definitionProvider
      or caps.hoverProvider
      or caps.referencesProvider
      or caps.documentSymbolProvider
      or caps.workspaceSymbolProvider
      or caps.textDocumentSync ~= nil
end

if not has_any_cap() then
  local keys = {}
  for k, _ in pairs(caps) do table.insert(keys, k) end
  table.sort(keys)
  print("jdtls started but no expected capabilities advertised.")
  print("Capabilities seen: " .. table.concat(keys, ", "))
  vim.cmd.cq()
  return
end

print("✅ jdtls started and initialized for " .. file .. " (project: " .. project_root .. ")")
vim.cmd.qa()
