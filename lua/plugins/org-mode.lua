return {
  {
    'nvim-orgmode/orgmode',

    config = function()
      -- Setup orgmode
      require('orgmode').setup({
        org_agenda_files = {
          "/home/iocanel/Documents/org/github.org",
          "/home/iocanel/Documents/org/habits.org",
          "/home/iocanel/Documents/org/nutrition.org",
          "/home/iocanel/Documents/org/workout.org",
          "/home/iocanel/Documents/org/calendars/personal.org",
          "/home/iocanel/Documents/org/calendars/work.org",
          "/home/iocanel/Documents/org/roam/Inbox.org",
        },
        org_default_notes_file = '~/Documents/org/roam/Inbox.org',
        mappings = {
          global = {
            org_agenda = '<leader>oa',
            org_capture = '<leader>ox',  -- Changed from default <leader>oc
          }
        }
      })
    end,
  },
  -- Org bullets (prettier headings)
  {
    "akinsho/org-bullets.nvim",
    ft = { "org" },
    config = function()
      require("org-bullets").setup({

        symbols = {
          -- list symbol
          list = "•",
          -- headlines can be a list
          headlines = { "◉", "○", "✸", "✿" },
        }
      })
    end,
  }
}
