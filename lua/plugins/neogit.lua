return {
  {
    "TimUntersberger/neogit",
    commit = "089d388876a535032ac6a3f80e19420f09e4ddda",
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
