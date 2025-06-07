package main

import "testing"

func Test{{_lua:(vim.fn.expand("%:t:r"):gsub("_test$", ""):gsub("(%w)(%w*)", function(first, rest) return first:upper() .. rest:lower() end))_}}(t *testing.T) {
    result := 0
    if result != 0 {
        t.Errorf("Expected 0, got %d", result)
    }
}
