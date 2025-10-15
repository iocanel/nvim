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
CONTAINER_BACKEND ?= ubuntu
CONTAINER_IMAGE = iocanel/nvim

container-build:
	$(MAKE) container-$(CONTAINER_BACKEND)-build

container-test: container-build
	$(MAKE) container-$(CONTAINER_BACKEND)-test

container-dev: container-build
	$(MAKE) container-$(CONTAINER_BACKEND)-dev

container-shell: container-build
	$(MAKE) container-$(CONTAINER_BACKEND)-shell

container-clean:
	docker rmi $(CONTAINER_IMAGE)-ubuntu $(CONTAINER_IMAGE)-nixos 2>/dev/null || true

# Ubuntu container targets
container-ubuntu-build:
	docker build -f Dockerfile.ubuntu -t $(CONTAINER_IMAGE)-ubuntu .

container-ubuntu-test: container-ubuntu-build
	docker run --rm $(CONTAINER_IMAGE)-ubuntu

container-ubuntu-dev: container-ubuntu-build
	docker run --rm -it -v $(PWD):/workspace $(CONTAINER_IMAGE)-ubuntu bash

container-ubuntu-shell: container-ubuntu-build
	docker run --rm -it -v $(PWD):/workspace $(CONTAINER_IMAGE)-ubuntu bash

# NixOS container targets
container-nixos-build:
	docker build -f Dockerfile.nixos -t $(CONTAINER_IMAGE)-nixos .

container-nixos-test: container-nixos-build
	docker run --rm -v $(PWD):/workspace $(CONTAINER_IMAGE)-nixos

container-nixos-dev: container-nixos-build
	docker run --rm -it -v $(PWD):/workspace $(CONTAINER_IMAGE)-nixos nix-shell

container-nixos-shell: container-nixos-build
	docker run --rm -it -v $(PWD):/workspace $(CONTAINER_IMAGE)-nixos bash

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
	@echo "Ubuntu Container (default):"
	@echo "  container-ubuntu-build   - Build Ubuntu-based container"
	@echo "  container-ubuntu-test    - Test in Ubuntu container"
	@echo "  container-ubuntu-dev     - Ubuntu development environment"
	@echo ""
	@echo "NixOS Container:"
	@echo "  container-nixos-build    - Build NixOS-based container"
	@echo "  container-nixos-test     - Test in NixOS container"
	@echo "  container-nixos-dev      - NixOS development environment"
	@echo ""
	@echo "Examples:"
	@echo "  make test                           # Test locally"
	@echo "  make container-test                 # Test in Ubuntu container (default)"
	@echo "  make CONTAINER_BACKEND=nixos container-test  # Test in NixOS container"
	@echo "  make container-ubuntu-test          # Test specifically in Ubuntu"
	@echo "  make container-nixos-test           # Test specifically in NixOS"
	@echo "  make container-dev                  # Interactive development"

.PHONY: help container-build container-test container-dev container-shell container-clean
