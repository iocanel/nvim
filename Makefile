all: test

test: test_java

test_java: jdtls dap_java

jdtls:
	nvim --headless "+luafile tests/java/jdtls.lua"

dap_java:
	nvim --headless "+luafile tests/java/dap.lua"
