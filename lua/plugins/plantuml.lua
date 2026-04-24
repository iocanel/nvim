local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
local plantuml_script = script_dir .. "/scripts/plantuml-docker.sh"

return {
  {
    "aklt/plantuml-syntax",
    ft = "plantuml",
    init = function()
      vim.g.plantuml_executable_script = plantuml_script
    end,
  },
  {
    "tyru/open-browser.vim",
    lazy = true,
  },
  {
    "weirongxu/plantuml-previewer.vim",
    ft = "plantuml",
    dependencies = {
      "aklt/plantuml-syntax",
      "tyru/open-browser.vim",
    },
    init = function()
      vim.g["plantuml_previewer#java_path"] = plantuml_script
      vim.g["plantuml_previewer#plantuml_jar_path"] = "/dev/null"
      vim.g["plantuml_previewer#save_format"] = "png"
    end,
  },
}
