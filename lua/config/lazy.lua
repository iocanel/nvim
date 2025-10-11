--
-- Lazy
--
vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)
require("lazy").setup({
  spec = {
    { "catppuccin/nvim" },
    -- add LazyVim and import its plugins
    -- { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import any extras modules here
    -- { import = "lazyvim.plugins.extras.lang.typescript" },
    -- { import = "lazyvim.plugins.extras.lang.json" },
    -- { import = "lazyvim.plugins.extras.ui.mini-animate" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- Pin to specific commits/tags for predictable behavior
    version = false, -- disable automatic version resolution for manual control
  },
  install = { 
    colorscheme = { "cattpuccin-latte" },
    -- Don't automatically install missing plugins
    missing = false,
  },
  -- Keep automatic updates disabled for predictable environment
  checker = { 
    enabled = false, -- disable automatic update checks
    notify = false,  -- disable update notifications
  },
  change_detection = {
    enabled = false, -- disable automatic config reload for stability
    notify = false,  -- disable change notifications
  },
  -- Git configuration for reproducible builds
  git = {
    log = { "-8" }, -- show last 8 commits when viewing git log
    timeout = 120,   -- git timeout in seconds
    url_format = "https://github.com/%s.git", -- use https for reproducibility
    filter = true,   -- use git clone --filter=blob:none for faster clones
  },
  performance = {
    cache = {
      enabled = true,
      path = vim.fn.stdpath("cache") .. "/lazy/cache",
      ttl = 3600 * 24 * 5, -- 5 days cache
    },
    reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
      -- disable some rtp plugins
      disabled_plugins = {
        "transparent",
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  -- UI customization with git commit info
  ui = {
    border = "none",
    size = {
      width = 0.8,
      height = 0.8,
    },
    custom_keys = {
      ["<localleader>d"] = function(plugin)
        vim.cmd("!git -C " .. plugin.dir .. " log --oneline -10")
      end,
    },
  },
})
