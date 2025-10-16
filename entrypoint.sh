#!/bin/bash

# Neovim container entrypoint script
# Copies baked-in configuration to user's home directory on first run

set -euo pipefail

# Ensure HOME is set (fallback to /tmp if running as non-standard user)
if [ -z "${HOME:-}" ]; then
    export HOME="/tmp"
fi

# Configuration directories
CONFIG_SOURCE="/nvim/.config/nvim"
DATA_SOURCE="/nvim/.local/share/nvim"
CONFIG_TARGET="$HOME/.config/nvim-docker"
DATA_TARGET="$HOME/.local/share/nvim-docker"

# Function to safely copy directory
safe_copy() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ ! -d "$target" ]; then
        mkdir -p "$(dirname "$target")"
        cp -r "$source" "$target"
    fi
}

# Copy configuration if it doesn't exist
safe_copy "$CONFIG_SOURCE" "$CONFIG_TARGET" "Neovim configuration"

# Copy data if it doesn't exist
safe_copy "$DATA_SOURCE" "$DATA_TARGET" "Neovim data"

# Set environment to use the copied versions
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export NVIM_APPNAME="nvim-docker"

# Pass through all arguments to nvim
exec nvim "$@"
