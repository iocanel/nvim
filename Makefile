all: test

test: test_java test_go test_python test_javascript test_typescript test_rust test_c

test_java: lsp_java dap_java

test_go: go_lsp go_dap

lsp_java:
	nvim --headless "+luafile tests/java/lsp.lua"

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

test_typescript: typescript_lsp typescript_dap

typescript_lsp:
	nvim --headless "+luafile tests/typescript/lsp.lua"

typescript_dap:
	nvim --headless "+luafile tests/typescript/dap.lua"

test_rust: rust_lsp rust_dap

rust_lsp:
	nvim --headless "+luafile tests/rust/lsp.lua"

rust_dap:
	nvim --headless "+luafile tests/rust/dap.lua"

test_c: c_lsp c_dap

c_lsp:
	nvim --headless "+luafile tests/c/lsp.lua"

c_dap:
	nvim --headless "+luafile tests/c/dap.lua"
