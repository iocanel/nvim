all: test

test: test_java test_go

test_java: jdtls dap_java

test_go: go_lsp go_dap

jdtls:
	nvim --headless "+luafile tests/java/jdtls.lua"

dap_java:
	nvim --headless "+luafile tests/java/dap.lua"

go_lsp:
	nvim --headless "+luafile tests/go/lsp.lua"

go_dap:
	nvim --headless "+luafile tests/go/dap.lua"
