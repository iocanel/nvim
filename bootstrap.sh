#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Neovim Bootstrap Script"
echo "======================="
echo ""
echo "This script will install all configured:"
echo "  - LSP servers"
echo "  - Debug adapters"
echo "  - Tree-sitter parsers"
echo ""

# Check if nvim is available
if ! command -v nvim &> /dev/null; then
  echo "Error: nvim command not found. Please install Neovim first."
  exit 1
fi

# First, ensure lazy.nvim plugins are installed
echo "Step 1: Installing/updating plugins with lazy.nvim..."
nvim --headless "+Lazy! sync" +qa

# Wait a moment for lazy to finish
sleep 2

# Run the bootstrap script
echo ""
echo "Step 2: Installing Tree-sitter parsers..."
nvim --headless -c "TSInstallSync java javascript typescript python go rust lua html css" -c "qa" 2>&1 | grep -E "(Installing|Installed|Compiling)" || true

echo ""
echo "Step 3: Installing Mason packages..."
echo "This may take several minutes. Please wait..."
nvim --headless -c "lua vim.cmd('MasonInstall html-lsp css-lsp json-lsp typescript-language-server vue-language-server js-debug-adapter lua-language-server rust-analyzer gopls pyright solidity intelephense ltex-ls clangd codelldb jdtls java-debug-adapter java-test delve debugpy')" -c "qa" 2>&1 &
MASON_PID=$!

# Wait for Mason installations with progress indicator
echo -n "Installing packages"
while kill -0 $MASON_PID 2>/dev/null; do
  echo -n "."
  sleep 2
done
wait $MASON_PID
echo " done!"

echo ""
echo "Bootstrap process completed!"
echo ""
echo "Note: Some packages may still be installing in the background."
echo "You can check the status by running ':Mason' in Neovim."
