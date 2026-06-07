# MASSIVIM

MASSIVIM is my portable NvChad-based Neovim config. It is tuned to work cleanly across NixOS, WSL, Ubuntu, Arch, macOS, and similar setups with minimal extra work.

## How It Looks

<img width="1768" height="1349" alt="image" src="https://github.com/user-attachments/assets/0de2cf08-b304-43fb-a26b-ab5c66959286" />

## Quick Start

```bash
# Back up any existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Install
git clone https://github.com/HughScott2002/MASSIVIM ~/.config/nvim

# Non-NixOS only
~/.config/nvim/setup.sh

# Launch
nvim
```

## How It Works

### NixOS

LSP servers and formatters are defined in `configuration.nix`, so Mason stays disabled.

### Everything Else

Run `setup.sh` once to install system dependencies. Mason handles the editor-side tooling on first launch.

## WSL2 Notes

WSL2 needs a little extra setup because package availability is uneven.

### 1. Install Neovim 0.11+

This config uses `vim.lsp.enable()` and `vim.lsp.config()`, which require Neovim 0.11 or newer.

```bash
brew install neovim
```

You can also install from the [Neovim releases page](https://github.com/neovim/neovim/releases).

### 2. Run the setup script

```bash
~/.config/nvim/setup.sh
```

This installs the usual CLI tools plus the pieces needed for `image.nvim`.

### 3. Make `image.nvim` work

`image.nvim` depends on:

- `luajit`
- `luarocks`
- `imagemagick`
- the `magick` rock

If you use `nix` on WSL:

```bash
nix-env -iA nixpkgs.luajit nixpkgs.luarocks nixpkgs.imagemagick
MAGICK_PC=$(find /nix/store -name "MagickWand.pc" 2>/dev/null | head -1)
PKG_CONFIG_PATH="$(dirname "$MAGICK_PC"):$PKG_CONFIG_PATH" luarocks --local --lua-version=5.1 install magick
```

To keep it around, add `PKG_CONFIG_PATH` to your shell profile.

If you use `brew` or `apt` instead:

```bash
# brew
brew install luarocks luajit imagemagick
luarocks --local --lua-version=5.1 install magick

# apt
sudo apt install luarocks imagemagick libmagickwand-dev
luarocks --local --lua-version=5.1 install magick
```

> `image.nvim` needs a terminal with Kitty graphics protocol support, such as Kitty or WezTerm.

## Included

- Theme: onedark with a pure black background
- LSPs: TypeScript, Rust, Go, Python, Lua, HTML/CSS, JSON, YAML, SQL, Bash, Docker, Java, Nix, Tailwind, Emmet
- Formatters: prettier, stylua, rustfmt, gofmt, black, google-java-format
- Plugins: harpoon, flash, lazygit, diffview, trouble, todo-comments, rainbow brackets, image.nvim, import-cost, nvim-ts-autotag, colorizer, markdown-preview, kulala
- Keymaps: `<leader>gg` lazygit, `<leader>ha` harpoon add, `s` flash jump, `<leader>cc` Claude Code, `<leader>fm` format, `<leader>xx` diagnostics

## Dependencies

### NixOS

Already handled in `configuration.nix`: ripgrep, fd, gcc, lazygit, tree-sitter, stylua, and the LSP stack.

### Non-NixOS

Run `setup.sh` or install these manually:

| Category | Packages |
| --- | --- |
| Required | `neovim` (0.11+), `git`, `gcc`, `make`, `unzip`, `curl` |
| Search / navigation | `ripgrep`, `fd` |
| Git | `lazygit` |
| Node | `nodejs`, `npm` |
| Treesitter | `tree-sitter-cli` |
| image.nvim | `luarocks`, `luajit`, `imagemagick`, `magick` |
| LSPs and formatters | Installed automatically by Mason |

## Credits

This repo provides the config, keymaps, setup scripts, and platform glue.

Upstream pieces:

- [NvChad](https://github.com/NvChad/NvChad) v2.5
- [mason.nvim](https://github.com/williamboman/mason.nvim) for LSP and formatter installs on non-NixOS systems
- [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for syntax and parsing
- [image.nvim](https://github.com/3rd/image.nvim) for inline image support
