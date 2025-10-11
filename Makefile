jdtls:
	nvim --headless "+luafile tests/jdtls.lua"

dap_java:
	nvim --headless "+luafile tests/dap_java.lua"

test: jdtls dap_java

all: test
