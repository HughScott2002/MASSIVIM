# MASSIVIM

My portable NVIM/NvChad config. Clone it, and it works — NixOS, WSL, Ubuntu, Arch, macOS, whatever.

## HOW IT LOOKS

<img width="1768" height="1349" alt="image" src="https://github.com/user-attachments/assets/0de2cf08-b304-43fb-a26b-ab5c66959286" />

## Quick Start

```bash
# Back up existing config if needed
mv ~/.config/nvim ~/.config/nvim.bak

# Clone
git clone https://github.com/HughScott2002/MASSIVIM ~/.config/nvim

# Non-NixOS only — install system deps
~/.config/nvim/setup.sh

# Launch
nvim
```

On **NixOS**, LSP servers and formatters are already in `configuration.nix`. Mason is disabled.

On **everything else**, `setup.sh` installs system deps, and Mason auto-installs LSPs/formatters on first launch.

## WSL2 Setup

WSL2 doesn't come with the same packages as a full NixOS or desktop Linux install. Extra steps:

### 1. Neovim >= 0.11 (required)

The config uses `vim.lsp.enable()` and `vim.lsp.config()` which require Neovim 0.11+. Most package managers ship older versions. Install via Homebrew (recommended on WSL):

```bash
brew install neovim   # gets 0.11+
```

Or via the [Neovim releases page](https://github.com/neovim/neovim/releases).

### 2. Run setup.sh

```bash
~/.config/nvim/setup.sh
```

This installs core tools (ripgrep, fd, lazygit, node, etc.), luarocks, ImageMagick, and the `magick` luarock.

### 3. image.nvim (luarocks + ImageMagick)

image.nvim needs three things that aren't installed by default on WSL2:

- **luajit** — Lua 5.1 runtime (Neovim's embedded Lua)
- **luarocks** — Lua package manager
- **ImageMagick** — image processing library
- **magick** luarock — Lua bindings for ImageMagick

If you're using **nix** as your package manager on WSL:

```bash
nix-env -iA nixpkgs.luajit nixpkgs.luarocks nixpkgs.imagemagick
```

Then install the magick rock. Nix puts ImageMagick's pkg-config files in the store, so you need to set `PKG_CONFIG_PATH`:

```bash
# Find MagickWand.pc
MAGICK_PC=$(find /nix/store -name "MagickWand.pc" 2>/dev/null | head -1)

# Install the rock
PKG_CONFIG_PATH="$(dirname $MAGICK_PC):$PKG_CONFIG_PATH" luarocks --local --lua-version=5.1 install magick
```

**Make it permanent** — add to your `~/.zshrc` or `~/.bashrc`:

```bash
export PKG_CONFIG_PATH="/nix/store/<your-imagemagick-dev-hash>/lib/pkgconfig:$PKG_CONFIG_PATH"
```

If you're using **brew** or **apt** instead:

```bash
# brew
brew install luarocks luajit imagemagick
luarocks --local --lua-version=5.1 install magick

# apt (Ubuntu/Debian)
sudo apt install luarocks imagemagick libmagickwand-dev
luarocks --local --lua-version=5.1 install magick
```

> **Note**: image.nvim requires a terminal with **Kitty graphics protocol** support (Kitty, WezTerm). Standard Windows Terminal / tmux will not render images.

### 4. Mason installs LSPs and formatters

On first launch, Mason will auto-install all LSP servers and formatters. Run `:Mason` to check progress. This can take a few minutes.

## What's Included

- **Theme**: onedark, pure black background (#000000)
- **LSP**: TypeScript, Rust, Go, Python, Lua, HTML/CSS, JSON, YAML, SQL, Bash, Docker, Java, Nix, Tailwind, Emmet
- **Formatters**: prettier, stylua, rustfmt, gofmt, black, google-java-format (format-on-save)
- **Plugins**: harpoon, flash, lazygit, diffview, trouble, todo-comments, rainbow brackets, image.nvim, import-cost, nvim-ts-autotag, colorizer, markdown-preview, kulala (REST client)
- **Key mappings**: `<leader>gg` lazygit, `<leader>ha` harpoon add, `s` flash jump, `<leader>cc` Claude Code, `<leader>fm` format, `<leader>xx` diagnostics

## Dependencies

### NixOS
Already handled in `configuration.nix` — ripgrep, fd, gcc, lazygit, tree-sitter, stylua, all LSP servers.

### Non-NixOS (WSL2, Ubuntu, Arch, macOS, etc.)

Run `setup.sh` or manually install:

| Category | Packages |
|----------|----------|
| **Required** | neovim (>= 0.11), git, gcc, make, unzip, curl |
| **Search/Navigation** | ripgrep, fd |
| **Git** | lazygit |
| **Node** | nodejs, npm |
| **Treesitter** | tree-sitter-cli (via npm) |
| **image.nvim** | luarocks, luajit, imagemagick, `magick` luarock |
| **LSPs & Formatters** | Auto-installed by Mason on first launch |

## Credits

Built on [NvChad](https://github.com/NvChad/NvChad) v2.5.
