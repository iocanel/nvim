{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "neovim-development-environment";
  
  buildInputs = with pkgs; [
    # Core utilities
    git
    curl
    wget
    unzip
    
    # Neovim editor
    neovim
    
    # Search and file utilities (from your home-manager config)
    fzf
    ripgrep
    fd
    jq
    yq
    tree-sitter
    bat
    eza
    tree
    
    # C/C++ Development (from your home-manager config)  
    cmake
    gdb
    lldb
    libtool
    
    # Java (exactly from your config)
    gradle
    temurin-bin-21
    
    # JavaScript/TypeScript (from your config)
    nodejs
    yarn-berry
    nodePackages.gulp
    nodePackages.ts-node
    typescript-language-server
    
    # Python (matching your config)
    (python312.withPackages (ps: with ps; [
      numpy
      pandas
      requests
      debugpy
    ]))
    
    # Rust (from your config)
    rustc
    rustfmt
    cargo
    rust-analyzer
    
    # Go (from your config)
    go
    gopls
    delve
    
    # Your exact codelldb setup
    vscode-extensions.vadimcn.vscode-lldb
    (pkgs.writeShellScriptBin "codelldb" ''
      EXT="${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb"
      export LD_LIBRARY_PATH="$EXT/lldb/lib"
      exec "$EXT/adapter/codelldb" --liblldb "$EXT/lldb/lib/liblldb.so" "$@"
    '')
    
    # Additional tools from your config
    gh
    pandoc
    xml2
    htop
    rsync
    zip
    util-linux
    
    # Build tools
    gnumake
    pkg-config
    autoconf
    automake
    
    # Additional development utilities
    stylua
  ];
  
  shellHook = ''
    echo "🚀 Neovim Development Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Available tools:"
    echo "  Languages: Java, Go, Rust, C/C++, JavaScript/TypeScript, Python"
    echo "  Debuggers: gdb, lldb, codelldb, delve, debugpy"
    echo "  Utilities: fzf, ripgrep, jq, tree-sitter"
    echo "  Build tools: make, cmake, gradle, cargo, npm"
    echo ""
    echo "🔧 LSP Servers available:"
    echo "  - clangd (C/C++) - install with: nix-shell -p clang-tools"
    echo "  - rust-analyzer (Rust) ✓"
    echo "  - gopls (Go) ✓"
    echo "  - typescript-language-server (JS/TS) ✓"
    echo "  - pyright (Python) - install with: nix-shell -p nodePackages.pyright"
    echo ""
    echo "🐛 Debuggers configured:"
    echo "  - gdb/lldb (C/C++) ✓"
    echo "  - codelldb (Rust) ✓"
    echo "  - delve (Go) ✓"
    echo "  - debugpy (Python) ✓"
    echo ""
    echo "💡 Your DWIM debugging system supports all these languages!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Environment setup
    export EDITOR=nvim
    export NVIM_CONFIG_DIR="$PWD"
    
    # Java environment (matching your home-manager setup)
    export JAVA_HOME="${pkgs.temurin-bin-21}"
    
    # Node.js environment  
    export NODE_PATH="${pkgs.nodejs}/lib/node_modules"
    
    # Python environment
    export PYTHONPATH="${pkgs.python312.withPackages (ps: with ps; [ debugpy ])}/lib/python3.12/site-packages:$PYTHONPATH"
    
    # Rust environment
    export RUST_SRC_PATH="${pkgs.rustc}/lib/rustlib/src/rust/library"
    
    echo "🎯 Environment configured! You can now:"
    echo "  - Run 'nvim' to start Neovim with full language support"
    echo "  - Run 'make test' to test all language configurations"
    echo "  - Use DebugDwim for intelligent debugging across all languages"
    echo ""
    echo "📝 Note: For full LSP support, you may want to install:"
    echo "  - clangd: nix-shell -p clang-tools"
    echo "  - pyright: nix-shell -p nodePackages.pyright"
    echo ""
  '';
  
  # Environment variables
  NIX_SHELL_PRESERVE_PROMPT = 1;
  NVIM_DEV_ENV = "true";
}