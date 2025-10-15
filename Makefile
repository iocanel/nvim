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

# Container targets (configurable backend)
CONTAINER_IMAGE = iocanel/nvim

# Ubuntu container targets
container-build:
	docker build -f Dockerfile.ubuntu -t $(CONTAINER_IMAGE)-ubuntu .

container-test: container-build
	docker run --rm $(CONTAINER_IMAGE)-ubuntu

container-dev: container-build
	docker run --rm -it $(CONTAINER_IMAGE)-ubuntu bash

container-shell: container-build
	docker run --rm -it $(CONTAINER_IMAGE)-ubuntu bash

# Help target
help:
	@echo "Neovim DWIM Debugging System - Available Targets"
	@echo "=================================================="
	@echo ""
	@echo "Language Tests:"
	@echo "  test              - Run all language tests"
	@echo "  test_java         - Test Java DAP/LSP (jdtls + dap_java)"
	@echo "  test_go           - Test Go DAP/LSP (go_lsp + go_dap)"
	@echo "  test_python       - Test Python DAP/LSP (python_lsp + python_dap)"
	@echo "  test_javascript   - Test JavaScript DAP/LSP"
	@echo "  test_typescript   - Test TypeScript DAP/LSP"
	@echo "  test_rust         - Test Rust DAP/LSP (rust_lsp + rust_dap)"
	@echo "  test_c            - Test C DAP/LSP (c_lsp + c_dap)"
	@echo ""
	@echo "Container Testing (Ubuntu by default, configurable):"
	@echo "  container-build   - Build container (CONTAINER_BACKEND=ubuntu|nixos)"
	@echo "  container-test    - Run all tests in container"
	@echo "  container-dev     - Interactive development environment"
	@echo "  container-shell   - Shell access to container"
	@echo "  container-clean   - Remove all container images"
	@echo ""
	@echo "Examples:"
	@echo "  make test                           # Test locally"
	@echo "  make container-test                 # Test in Ubuntu container (default)"
	@echo "  make container-dev                  # Interactive development"

.PHONY: help container-build container-test container-dev container-shell container-clean
