CONTAINER_IMAGE = iocanel/nvim
UID := $(shell id -u)
GID := $(shell id -g)
HOME_DIR := $(HOME)
DOCKER_RUN = docker run --rm -i -v $(HOME_DIR):$(HOME_DIR) --user $(UID):$(GID) -e HOME=$(HOME_DIR) --tmpfs /tmp/nvim-state:uid=$(UID),gid=$(GID) -e XDG_STATE_HOME=/tmp/nvim-state $(CONTAINER_IMAGE)

all: test

test: c-test go-test java-test javascript-test python-test rust-test typescript-test

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
	@find tests/javascript -name "package-lock.json" -type f -delete 2>/dev/null || true
	@find tests/javascript -name "*.js.map" -type f -delete 2>/dev/null || true
	@find tests/typescript -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/typescript -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/typescript -name "package-lock.json" -type f -delete 2>/dev/null || true
	@find tests/typescript -name "*.js" -type f -delete 2>/dev/null || true
	@find tests/typescript -name "*.js.map" -type f -delete 2>/dev/null || true
	# Python test projects
	@find tests/python -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find tests/python -name "*.pyc" -type f -delete 2>/dev/null || true
	@find tests/python -name "*.pyo" -type f -delete 2>/dev/null || true
	@find tests/python -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "✅ All test project build artifacts cleaned"

#
# C
#
c-lsp:
	nvim --headless "+luafile tests/c/lsp.lua"

c-dap:
	nvim --headless "+luafile tests/c/dap.lua"

c-test: c-lsp c-dap

c-container-test:
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/c/lsp.lua"
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/c/dap.lua"


#
# Go
#
go-lsp:
	nvim --headless "+luafile tests/go/lsp.lua"

go-dap:
	nvim --headless "+luafile tests/go/dap.lua"

go-test: go-lsp go-dap

go-container-test:
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/go/lsp.lua"
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/go/dap.lua"

#
# Java
#
java-lsp:
	nvim --headless "+luafile tests/java/lsp.lua"

java-dap:
	nvim --headless "+luafile tests/java/dap.lua"

java-test: java-lsp java-dap

java-container-test:
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/java/lsp.lua"
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/java/dap.lua"

#
# Javascript
#
javascript-lsp:
	nvim --headless "+luafile tests/java/lsp.lua"

javascript-dap:
	nvim --headless "+luafile tests/java/dap.lua"

javascript-test: javascript-lsp javascript-dap

javascript-container-test:
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/javascript/lsp.lua"
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/javascript/dap.lua"

#
# Python
#
python-lsp:
	nvim --headless "+luafile tests/python/lsp.lua"

python-dap:
	nvim --headless "+luafile tests/python/dap.lua"

python-test: python-lsp python-dap

python-container-test:
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/python/lsp.lua"
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/python/dap.lua"

#
# Rust
#
rust-lsp:
	nvim --headless "+luafile tests/rust/lsp.lua"

rust-dap:
	nvim --headless "+luafile tests/rust/dap.lua"

rust-test: rust-lsp rust-dap

rust-container-test:
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/rust/lsp.lua"
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/rust/dap.lua"

#
# TypeScript
#

typescript-lsp:
	nvim --headless "+luafile tests/typescript/lsp.lua"

typescript-dap:
	nvim --headless "+luafile tests/typescript/dap.lua"

typescript-test: typescript-lsp typescript-dap

typescript-container-test:
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/typescript/lsp.lua"
	$(DOCKER_RUN) --headless "+luafile /workspace/tests/typescript/dap.lua"


#
#
# Container Image
# (Building, Testing, Development, Shell Access)
#
#

container-build:
	docker build -f Dockerfile.ubuntu -t $(CONTAINER_IMAGE) .

container-test: container-build c-container-test go-container-test java-container-test javascript-container-test python-container-test rust-container-test typescript-container-test

container-dev: container-build
	docker run --rm -it $(CONTAINER_IMAGE) bash

container-shell: container-build
	$(DOCKER_RUN)

# Help target
help:
	@echo "Neovim DWIM Debugging System - Available Targets"
	@echo "=================================================="
	@echo ""
	@echo "Language Tests:"
	@echo "  test              - Run all language tests"
	@echo "  clean             - Clean all test project build artifacts"
	@echo "  test_java         - Test Java DAP/LSP (jdtls + dap_java)"
	@echo "  test_go           - Test Go DAP/LSP (go-lsp + go-dap)"
	@echo "  test_python       - Test Python DAP/LSP (python-lsp + python-dap)"
	@echo "  test_javascript   - Test JavaScript DAP/LSP"
	@echo "  test_typescript   - Test TypeScript DAP/LSP"
	@echo "  test_rust         - Test Rust DAP/LSP (rust-lsp + rust-dap)"
	@echo "  test_c            - Test C DAP/LSP (c-lsp + c-dap)"
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
