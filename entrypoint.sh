#!/bin/bash

# Neovim container entrypoint script
# Uses container's baked-in config directly with volume-mounted data for persistence

set -euo pipefail

# All paths under /nvim/ for consistency
# Config from container (read-only, always up-to-date with image)
export XDG_CONFIG_HOME="/nvim/.config"

# Data from volume (writable, initialized from container on first use)
export XDG_DATA_HOME="/nvim/.local/share"

# State and cache are ephemeral (tmpfs mounted by ivvim, or writable dirs in container)
export XDG_STATE_HOME="/nvim/.local/state"
export XDG_CACHE_HOME="/nvim/.cache"

# Use standard nvim app name since we're using container paths
export NVIM_APPNAME="nvim"

# Ensure ephemeral directories exist
mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# Pass through all arguments to nvim
exec nvim "$@"
