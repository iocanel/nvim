all: test

test: test_java test_go test_python test_javascript test_typescript test_rust test_c

# Clean all build artifacts from test projects
clean:
	@echo "Cleaning all test project build artifacts..."
	# Java test projects
	@find tests/java -name "target" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/java -name "*.class" -type f -delete 2>/dev/null || true
	# Go test projects  
	@find tests/go -name "go.sum" -type f -delete 2>/dev/null || true
	@find tests/go -name "__debug_bin*" -type f -delete 2>/dev/null || true
	# Rust test projects
	@find tests/rust -name "target" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/rust -name "Cargo.lock" -type f -delete 2>/dev/null || true
	# C test projects
	@find tests/c -name "*.o" -type f -delete 2>/dev/null || true
	@find tests/c -name "hello_world" -type f -delete 2>/dev/null || true
	@find tests/c -name "test_helloworld" -type f -delete 2>/dev/null || true
	@find tests/c -name "test_main" -type f -delete 2>/dev/null || true
	# JavaScript/TypeScript test projects
	@find tests/javascript -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/javascript -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/javascript -name "*.js.map" -type f -delete 2>/dev/null || true
	@find tests/typescript -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/typescript -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/typescript -name "*.js" -type f -delete 2>/dev/null || true
	@find tests/typescript -name "*.js.map" -type f -delete 2>/dev/null || true
	# Python test projects
	@find tests/python -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/python -name "*.pyc" -type f -delete 2>/dev/null || true
	@find tests/python -name "*.pyo" -type f -delete 2>/dev/null || true
	@find tests/python -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "✅ All test project build artifacts cleaned"

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
	@echo "  clean             - Clean all test project build artifacts"
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

.PHONY: help clean container-build container-test container-dev container-shell container-clean
