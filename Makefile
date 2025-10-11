all: test

test: test_java test_go test_python test_javascript

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

test_python: python_lsp python_dap

python_lsp:
	nvim --headless "+luafile tests/python/lsp.lua"

python_dap:
	nvim --headless "+luafile tests/python/dap.lua"

test_javascript: javascript_lsp javascript_dap

javascript_lsp:
	nvim --headless "+luafile tests/javascript/lsp.lua"

javascript_dap:
	nvim --headless "+luafile tests/javascript/dap.lua"
