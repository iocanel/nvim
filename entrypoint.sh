#!/bin/bash

# Neovim container entrypoint script
# Uses container's baked-in config directly with volume-mounted data for persistence
# Environment variables can be overridden via docker run -e

set -euo pipefail

# All paths under /nvim/ by default (can be overridden via docker run -e)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/nvim/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/nvim/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-/nvim/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/nvim/.cache}"
export NVIM_APPNAME="${NVIM_APPNAME:-nvim}"

# Ensure ephemeral directories exist
mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME" 2>/dev/null || true

# Pass through all arguments to nvim
exec nvim "$@"
