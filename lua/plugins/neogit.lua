return {
  {
    "NeogitOrg/neogit",
    opts = {
      disable_signs = false,
      disable_hint = true,
      disable_commit_confirmation = true,
      auto_refresh = true,
      -- customize displayed signs
      signs = {
        -- { CLOSED, OPENED }
        section = { "", "" },
        item = { "", "" },
        hunk = { "", "" },
      },
    }
  }
}
