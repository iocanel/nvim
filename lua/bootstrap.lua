-- Bootstrap script for installing all Neovim dependencies
-- This script installs:
-- 1. Tree-sitter parsers
-- 2. Mason LSP servers
-- 3. Debug adapters

local M = {}

-- Tree-sitter parsers to install
local treesitter_parsers = {
  'java',
  'javascript',
  'typescript',
  'python',
  'go',
  'rust',
  'lua',
  'html',
  'css',
}

-- Mason packages (LSP servers, DAPs, formatters, linters)
-- Note: These are Mason package names, not LSP server names
local mason_packages = {
  'html-lsp',
  'css-lsp',
  'json-lsp',
  'typescript-language-server',
  'vue-language-server',
  'js-debug-adapter',
  'lua-language-server',
  'rust-analyzer',
  'gopls',
  'pyright',
  'solidity',
  'intelephense',
  'ltex-ls',
  'clangd',
  'codelldb',
  'jdtls',
  'java-debug-adapter',
  'java-test',
  'delve',
  'debugpy',
}

function M.install_treesitter_parsers()
  print("Installing Tree-sitter parsers...")

  local status_ok, treesitter = pcall(require, "nvim-treesitter.install")
  if not status_ok then
    print("Error: nvim-treesitter not found. Please install plugins first with :Lazy sync")
    return false
  end

  for _, parser in ipairs(treesitter_parsers) do
    print("Installing parser: " .. parser)
    vim.cmd("TSInstall " .. parser)
  end

  print("Tree-sitter parsers installation completed!")
  return true
end

function M.install_mason_packages()
  print("Installing Mason packages...")

  local status_ok, mason_registry = pcall(require, "mason-registry")
  if not status_ok then
    print("Error: mason-registry not found. Please install plugins first with :Lazy sync")
    return false
  end

  local installed = 0
  local failed = {}

  for _, package_name in ipairs(mason_packages) do
    local ok, package = pcall(mason_registry.get_package, package_name)

    if ok then
      if not package:is_installed() then
        print("Installing: " .. package_name)
        package:install():once("closed", vim.schedule_wrap(function()
          if package:is_installed() then
            print("Successfully installed: " .. package_name)
            installed = installed + 1
          else
            print("Failed to install: " .. package_name)
            table.insert(failed, package_name)
          end
        end))
      else
        print("Already installed: " .. package_name)
        installed = installed + 1
      end
    else
      print("Package not found: " .. package_name)
      table.insert(failed, package_name)
    end
  end

  vim.defer_fn(function()
    print(string.format("\nMason installation summary:"))
    print(string.format("  Successfully installed: %d packages", installed))
    if #failed > 0 then
      print(string.format("  Failed: %d packages", #failed))
      print("  Failed packages: " .. table.concat(failed, ", "))
    end
  end, 5000)

  return true
end

function M.bootstrap_all()
  print("Starting Neovim bootstrap process...")
  print("This will install all LSP servers, debug adapters, and tree-sitter parsers.")
  print("")

  vim.defer_fn(function()
    M.install_treesitter_parsers()
  end, 1000)

  vim.defer_fn(function()
    M.install_mason_packages()
  end, 2000)
end

-- Create user command for manual bootstrap
vim.api.nvim_create_user_command('Bootstrap', function()
  M.bootstrap_all()
end, { desc = 'Install all LSP servers, debug adapters, and tree-sitter parsers' })

-- Check if bootstrap is needed on first startup
function M.check_and_bootstrap()
  local mason_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_ok then
    return
  end

  local treesitter_ok = pcall(require, "nvim-treesitter.install")
  if not treesitter_ok then
    return
  end

  local missing_packages = 0

  for _, package_name in ipairs(mason_packages) do
    local ok, package = pcall(mason_registry.get_package, package_name)
    if ok and not package:is_installed() then
      missing_packages = missing_packages + 1
    end
  end

  local missing_parsers = 0
  for _, parser in ipairs(treesitter_parsers) do
    local parser_path = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser/" .. parser .. ".so"
    if vim.fn.filereadable(parser_path) == 0 then
      missing_parsers = missing_parsers + 1
    end
  end

  if missing_packages > 0 or missing_parsers > 0 then
    print(string.format("[Bootstrap] Detected %d missing Mason packages and %d missing Tree-sitter parsers", missing_packages, missing_parsers))
    print("[Bootstrap] Running automatic bootstrap...")
    M.bootstrap_all()
  end
end

-- Auto-run bootstrap on first VimEnter (only if needed)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      M.check_and_bootstrap()
    end, 1000)
  end,
  once = true,
})

return M
