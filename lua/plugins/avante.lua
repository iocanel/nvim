return {
  "yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  --
  --
  -- Note: I had to:
  -- > cd .local/share/nvim/lazy/avante.nvim/
  -- > make
  build = function()
    -- conditionally use the correct build system for the current OS
    if vim.fn.has("win32") == 1 then
      return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    else
      return "make BUILD_FROM_SOURCE=true"
    end
  end,
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  keys = {
    { '<leader>aa', "<cmd>AvanteAsk<cr>", desc = 'avante ask' },
    { '<leader>at', "<cmd>AvanteToggle<cr>", desc = 'avante toggle' },
    { '<leader>ax', "<cmd>AvanteClear<cr>", desc = 'avante clear' },
    { '<leader>am', "<cmd>AvanteModels<cr>", desc = 'avante models' },
    { '<leader>ah', "<cmd>AvanteHistory<cr>", desc = 'avante history select' },
    { '<leader>ae', "<cmd>AvanteEdit<cr>", desc = 'avante edit selected block', mode = 'v' },
  },
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    -- add any opts here
    mode = "agentic",
    provider = "copilot",
    providers = {
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4o-mini",
        timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 16384,
          },
      },
      anthropic = {
        endpoint = "https://api.anthropic.com",
        model = "claude-3.7-sonnet",
        timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
      },
      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model = "claude-3.7-sonnet",
        timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "echasnovski/mini.pick", -- for file_selector provider mini.pick
    "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    "stevearc/dressing.nvim", -- for input provider dressing
    "folke/snacks.nvim", -- for input provider snacks
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    "nvim-neo-tree/neo-tree.nvim", -- for neotree support,
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
