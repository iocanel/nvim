return {
  {
    "NeogitOrg/neogit",
    commit = "0cae7abc30cb91d661f28257c331fcb5b5198e31",
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
