# Neovim Configuration

A comprehensive Neovim configuration using Lua and the lazy.nvim plugin manager, optimized for modern software development with extensive language support and debugging capabilities.

## 🌐 Supported Languages

| Language | LSP | DAP | Treesitter | Tests | Status |
|----------|-----|-----|------------|-------|--------|
| Java | ✅ | ✅ | ✅ | ✅ | [![Java](https://github.com/iocanel/nvim/actions/workflows/java.yml/badge.svg?event=push)](https://github.com/iocanel/nvim/actions/workflows/java.yml) |
| Go | ✅ | ✅ | ✅ | ✅ | [![Go](https://github.com/iocanel/nvim/actions/workflows/go.yml/badge.svg?event=push)](https://github.com/iocanel/nvim/actions/workflows/go.yml) |
| Python | ✅ | ✅ | ✅ | ✅ | [![Python](https://github.com/iocanel/nvim/actions/workflows/python.yml/badge.svg?event=push)](https://github.com/iocanel/nvim/actions/workflows/python.yml) |
| JavaScript | ✅ | ✅ | ✅ | ✅ | [![JavaScript](https://github.com/iocanel/nvim/actions/workflows/javascript.yml/badge.svg?event=push)](https://github.com/iocanel/nvim/actions/workflows/javascript.yml) |
| TypeScript | ✅ | ✅ | ✅ | ✅ | [![TypeScript](https://github.com/iocanel/nvim/actions/workflows/typescript.yml/badge.svg?event=push)](https://github.com/iocanel/nvim/actions/workflows/typescript.yml) |
| Rust | ✅ | ✅ | ✅ | ✅ | [![Rust](https://github.com/iocanel/nvim/actions/workflows/rust.yml/badge.svg?event=push)](https://github.com/iocanel/nvim/actions/workflows/rust.yml) |
| C/C++ | ✅ | ✅ | ✅ | ✅ | [![C/C++](https://github.com/iocanel/nvim/actions/workflows/c.yml/badge.svg?event=push)](https://github.com/iocanel/nvim/actions/workflows/c.yml) |
| Vue | ✅ | ✅ | ✅ | ➖ | N/A |
| Lua | ✅ | ➖ | ✅ | ➖ | N/A |
| HTML/CSS | ✅ | ➖ | ✅ | ➖ | N/A |
| PHP | ✅ | ➖ | ➖ | ➖ | N/A |
| Solidity | ✅ | ➖ | ➖ | ➖ | N/A |

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/iocanel/nvim/main/setup.sh | bash
```

Then use the editor with `invim`:
```bash
invim .              # Open current directory
invim myfile.txt     # Edit a specific file
```


## 🏗️ Core Building Blocks

### Plugin Manager
- **[lazy.nvim](https://github.com/folke/lazy.nvim)** - Modern plugin manager with lazy loading support

### Language Server Protocol (LSP)
- **[mason.nvim](https://github.com/williamboman/mason.nvim)** - Portable package manager for LSP servers
- **[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)** - Quickstart configs for Neovim LSP
- **[mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)** - Bridge mason.nvim with nvim-lspconfig

### Syntax Highlighting
- **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)** - Modern syntax highlighting and code understanding

### Debug Adapter Protocol (DAP)
- **[nvim-dap](https://github.com/mfussenegger/nvim-dap)** - Debug Adapter Protocol client
- **[nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)** - UI for nvim-dap
- **[nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text)** - Virtual text support for debugging

## 🚀 Key Features

### Java Development Excellence
- **JDTLS Integration**: Advanced Java LSP with Eclipse JDT support
- **JPA Utilities**: Entity navigation and DTO generation
- **Remote Debugging**: DAP configuration for remote Java debugging
- **Maven Integration**: Custom Maven commands and operations
- **Standalone Projects**: Quick Eclipse project setup with `JdtStandalone`

### AI-Powered Development
- **Multiple AI Assistants**: Avante, ChatGPT, Copilot, Codeium integration
- **Intelligent Code Completion**: Enhanced completion with AI suggestions
- **Code Generation**: Template-based code generation for multiple languages

### Advanced Git Integration
- **[Fugitive](https://github.com/tpope/vim-fugitive)**: Comprehensive Git commands
- **[Gitsigns](https://github.com/lewis6991/gitsigns.nvim)**: Git decorations and hunk operations
- **[Neogit](https://github.com/NeogitOrg/neogit)**: Magit-inspired Git interface
- **[Octo](https://github.com/pwntester/octo.nvim)**: GitHub integration for PRs and issues

### Navigation & Search
- **[Telescope](https://github.com/nvim-telescope/telescope.nvim)**: Fuzzy finder for files, buffers, and more
- **[Hop](https://github.com/phaazon/hop.nvim)**: Lightning-fast cursor movement
- **[Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim)**: Modern file explorer

### Templates & Productivity
- **Template System**: Ready-to-use templates for various languages and frameworks
- **Auto-save**: Automatic file saving to prevent data loss
- **Multiple Cursors**: Efficient multi-cursor editing
- **Toggle Terminal**: Integrated terminal management

## ⌨️ Key Mappings

> **Leader Key**: `<Space>`

### 📂 Open Operations (`<leader>o`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>of` | Telescope find_files | Open files with fuzzy search |
| `<leader><space>` | Telescope find_files | Quick file access |
| `<leader>ob` | Telescope buffers | Open buffer list |
| `<leader>or` | Telescope oldfiles | Open recent files |
| `<leader>od` | Telescope zoxide | Open directory with zoxide |
| `<leader>oc` | ToggleTerm | Open terminal |
| `<leader>ot` | Neotree | Open file tree |

### 🔍 Search Operations (`<leader>s`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>sf` | Telescope find_files | Search files |
| `<leader>sg` | Telescope live_grep | Search with grep |
| `<leader>sw` | Telescope grep_string | Search current word |
| `<leader>sb` | Telescope current_buffer | Search in current buffer |
| `<leader>sh` | Telescope help_tags | Search help documentation |
| `<leader>sd` | Telescope diagnostics | Search diagnostics |

### 🪟 Window Operations (`<leader>w`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>wsh` | horizontal split | Split window horizontally |
| `<leader>wsv` | vertical split | Split window vertically |
| `<leader>wjh` | `<C-w>h` | Jump to left window |
| `<leader>wjv` | `<C-w>v` | Jump to right window |
| `<leader>wc` | quit | Close current window |
| `<leader>wp` | winpick.select | Pick window interactively |

### 🌳 Git Operations (`<leader>g`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>gc` | Git commit | Create git commit |
| `<leader>gs` | Gitsigns stage_buffer | Stage current buffer |
| `<leader>ghn` | Gitsigns next_hunk | Go to next hunk |
| `<leader>ghp` | Gitsigns prev_hunk | Go to previous hunk |
| `<leader>ghs` | Gitsigns stage_hunk | Stage current hunk |
| `<leader>ghu` | Gitsigns undo_stage_hunk | Undo stage hunk |
| `<leader>ghr` | Gitsigns reset_hunk | Reset current hunk |
| `<leader>gg` | Neogit | Open Neogit interface |
| `<leader>gt` | Tardis git | Git time machine |
| `<leader>gO` | Octo | Open Octo GitHub interface |

#### GitHub Operations (`<leader>go`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>gopl` | Octo pr list | List pull requests |
| `<leader>gopc` | Octo pr checkout | Checkout pull request |
| `<leader>gopm` | Octo pr merge | Merge pull request |
| `<leader>gopd` | Octo pr diff | Show PR diff |
| `<leader>gopR` | Octo pr reload | Reload pull request |
| `<leader>gopb` | Octo pr browser | Open PR in browser |
| `<leader>goprs` | OctoReviewStartOrSubmit | Start or submit review |
| `<leader>goprc` | Octo review close | Close review |
| `<leader>goprd` | Octo review discard | Discard review |
| `<leader>goil` | Octo issues list | List issues |
| `<leader>goic` | Octo issue close | Close issue |
| `<leader>goiR` | Octo issue reload | Reload issue |
| `<leader>goib` | Octo issue browser | Open issue in browser |
| `<leader>goru` | Octo reaction thumbs_up | Add thumbs up reaction |
| `<leader>gord` | Octo reaction thumbs_down | Add thumbs down reaction |
| `<leader>gort` | Octo reaction tada | Add tada reaction |
| `<leader>gorh` | Octo reaction heart | Add heart reaction |
| `<leader>gorr` | Octo reaction rocket | Add rocket reaction |
| `<leader>gorp` | Octo reaction party | Add party reaction |
| `<leader>goa` | Octo actions | Show Octo actions |

### 🛠️ LSP Operations (`<leader>l`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>lrn` | vim.lsp.buf.rename | Rename symbol |
| `<leader>lca` | vim.lsp.buf.code_action | Show code actions |
| `<leader>lgd` | vim.lsp.buf.definition | Go to definition |
| `<leader>lgr` | Telescope lsp_references | Go to references |
| `<leader>lgi` | vim.lsp.buf.implementation | Go to implementation |
| `<leader>ltd` | vim.lsp.buf.type_definition | Go to type definition |
| `<leader>ldh` | vim.lsp.buf.hover | Show hover documentation |
| `<leader>lds` | vim.lsp.buf.signature_help | Show signature help |
| `<leader>lf` | vim.lsp.buf.format | Format buffer |

### 🐛 Debug Operations (`<leader>d`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>dd` | DebugDwim | Smart debug start |
| `<leader>da` | attach_to_remote | Attach to remote debugger |
| `<leader>dc` | DapContinue | Continue execution |
| `<leader>di` | DapStepIn | Step into function |
| `<leader>do` | DapStepOver | Step over line |
| `<leader>dO` | DapStepOut | Step out of function |
| `<leader>db` | DapToggleBreakpoint | Toggle breakpoint |
| `<leader>dr` | DapToggleRepl | Toggle REPL |
| `<leader>dui` | dapui.toggle | Toggle debug UI |

### 🔄 Toggle Operations (`<leader>t`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>tt` | Neotree toggle | Toggle file tree |
| `<leader>tu` | Telescope undo | Toggle undo tree |
| `<leader>ts` | TemplateSelect | Select and insert template |

### ✨ Editor Operations (`<leader>e`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>es` | statusline_toggle | Toggle status line |
| `<leader>en` | linenumber_toggle | Toggle line numbers |
| `<leader>ef` | focus_toggle | Toggle focus mode |

### 🤖 AI Assistant Operations (`<leader>c`)
| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>cpc` | CopilotChat | Open Copilot chat |
| `<leader>cpf` | CopilotChatFix | Copilot fix suggestions |
| `<leader>cpe` | CopilotChatExplain | Copilot explanations |

## 📁 Project Structure

```
├── init.lua                 # Main entry point
├── lua/
│   ├── config/             # Core configuration
│   │   ├── options.lua     # Neovim options and settings
│   │   ├── keymaps.lua     # Key mappings and bindings
│   │   ├── lazy.lua        # Plugin manager setup
│   │   ├── java.lua        # Java-specific utilities
│   │   └── dap/            # Debug adapter configurations
│   ├── plugins/            # Plugin specifications
│   └── themes/             # Color scheme configurations
├── templates/              # Language-specific templates
├── tests/                  # Language-specific test suites
└── ftplugin/               # Filetype-specific configurations
```

## 🚀 Quick Start

1. **Prerequisites**: Ensure you have Neovim 0.9+ installed
2. **Clone**: Place this configuration in your Neovim config directory
3. **Install**: Run `nvim` and lazy.nvim will automatically install plugins
4. **Language Support**: Use `:Mason` to install additional language servers
5. **Templates**: Use `<leader>ts` to explore available code templates

## 🧪 Testing

The configuration includes comprehensive tests for all supported languages:

```bash
# Run all tests
make test

# Test specific language
make test_java
make test_go
make test_python
# ... etc
```

## 🎨 Customization

- **Themes**: Multiple themes available in `lua/themes/`
- **Templates**: Add custom templates in `templates/` directory
- **Java Utilities**: Extend Java-specific features in `lua/config/java.lua`
- **Key Mappings**: Customize bindings in `lua/config/keymaps.lua`

---

This configuration prioritizes developer productivity with intelligent defaults, comprehensive language support, and efficient workflows. The extensive testing suite ensures reliability across all supported languages and features.
