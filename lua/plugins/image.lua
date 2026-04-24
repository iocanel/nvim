return {
  "3rd/image.nvim",
  ft = { "markdown", "svg" },
  opts = {
    backend = "kitty",
    processor = "magick_cli",
    integrations = {
      markdown = { enabled = true },
    },
    max_width_window_percentage = 100,
    max_height_window_percentage = 100,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif", "*.svg" },
    editor_only_render_when_focused = false,
  },
  config = function(_, opts)
    local image = require("image")
    image.setup(opts)

    local watched = {}

    local function watch(path, buf)
      if watched[path] then return end
      local handle = vim.uv.new_fs_event()
      if not handle then return end

      handle:start(path, {}, function()
        handle:stop()
        watched[path] = nil
        vim.defer_fn(function()
          if not vim.api.nvim_buf_is_valid(buf) then return end
          if vim.fn.bufwinid(buf) == -1 then return end
          local images = image.get_images({ buffer = buf })
          for _, img in ipairs(images) do
            img:render()
          end
          watch(path, buf)
        end, 500)
      end)
      watched[path] = handle
    end

    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = opts.hijack_file_patterns,
      callback = function(ev)
        local path = vim.api.nvim_buf_get_name(ev.buf)
        watch(path, ev.buf)
      end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
      callback = function(ev)
        local path = vim.api.nvim_buf_get_name(ev.buf)
        if watched[path] then
          watched[path]:stop()
          watched[path] = nil
        end
      end,
    })
  end,
}
