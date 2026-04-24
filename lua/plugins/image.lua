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
    editor_only_render_when_focused = true,
  },
}
