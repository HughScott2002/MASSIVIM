# MASSIVIM

[![NixOS](https://img.shields.io/badge/NixOS-ready-5277C3?logo=nixos&logoColor=white)](https://nixos.org/)
[![Neovim](https://img.shields.io/badge/Neovim-0.11+-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![NvChad](https://img.shields.io/badge/NvChad-v2.5-6D57A8)](https://nvchad.com/)
[![Lua](https://img.shields.io/badge/Lua-config-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)

Portable NvChad config. NixOS first. Works elsewhere with Neovim 0.11+.

## Screenshot

<img width="1768" height="1349" alt="image" src="https://github.com/user-attachments/assets/0de2cf08-b304-43fb-a26b-ab5c66959286" />

## AI Install Prompts

### NixOS

```text
Install MASSIVIM on NixOS.

Repo: https://github.com/HughScott2002/MASSIVIM
Path: ~/.config/nvim

Edit configuration.nix with the README NixOS package block. Use system packages for LSPs and formatters. Mason is disabled on NixOS.

Keep AI CLIs separate. Use nixos-unstable only for packages shown as unstable.*.

Before finishing, check OS package names, Neovim version, PATH, language runtimes, and NixOS vs Mason behavior. Fix launch blockers.

Back up ~/.config/nvim, rebuild with sudo nixos-rebuild switch, clone MASSIVIM, then open nvim once.
```

### Non-NixOS

```text
Install MASSIVIM.

Repo: https://github.com/HughScott2002/MASSIVIM
Path: ~/.config/nvim

Back up ~/.config/nvim. Clone the repo. Run ~/.config/nvim/setup.sh. Open nvim once so lazy.nvim and Mason install tools.

Install needed runtimes yourself: Rust/rustfmt, Zig/zigfmt, Go/gofmt, Java, .NET, PHP, and Deno.

Before finishing, check OS package names, Neovim version, PATH, language runtimes, and Mason tools that still need system runtimes. Fix launch blockers.
```

## Quick Start

> Warning: NixOS is the main target. Non-NixOS needs Neovim 0.11+ and some runtimes outside Mason.

### NixOS

Add this to `configuration.nix`:

```nix
{ pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
  };
in
{
  environment.systemPackages = with pkgs; [
    # Neovim and plugin tools
    neovim
    git
    gcc
    gnumake
    ripgrep
    fd
    lazygit
    unstable.nodejs
    unzip
    curl
    tree-sitter
    jdk21_headless
    dotnet-sdk_10

    # LSPs
    nil
    lua-language-server
    typescript-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    emmet-ls
    pyright
    gopls
    rust-analyzer
    unstable.zls
    bash-language-server
    dockerfile-language-server
    yaml-language-server
    sqls
    clang-tools
    cmake-language-server
    lemminx
    deno
    phpactor
    jdt-language-server
    roslyn-ls

    # Java debug/test
    vscode-extensions.vscjava.vscode-java-debug
    vscode-extensions.vscjava.vscode-java-test

    # Formatters
    stylua
    black
    prettier
    google-java-format
    rustfmt
    unstable.zig
    unstable.go
    php84Packages.php-cs-fixer
  ];
}
```

Add unstable if needed:

```bash
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
sudo nix-channel --update
```

Install:

```bash
sudo nixos-rebuild switch
mv ~/.config/nvim ~/.config/nvim.bak
git clone https://github.com/HughScott2002/MASSIVIM ~/.config/nvim
nvim
```

`unstable.*` only uses `nixos-unstable` for that package.

### Optional AI CLIs

```nix
{ pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
  };
in
{
  environment.systemPackages = with pkgs; [
    unstable.codex
    unstable.opencode
    unstable.claude-code
  ];
}
```

### Non-NixOS

```bash
mv ~/.config/nvim ~/.config/nvim.bak
git clone https://github.com/HughScott2002/MASSIVIM ~/.config/nvim
~/.config/nvim/setup.sh
nvim
```

Manual runtimes: Rust/rustfmt, Zig/zigfmt, Go/gofmt, Java, .NET, PHP, Deno.

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

If you use tmux (>= 3.3), add this to `~/.tmux.conf`:

```tmux
set -gq allow-passthrough on
set -g visual-activity off
set-option -g focus-events on
```

Without that, MASSIVIM now disables `image.nvim` and shows a warning instead of crashing on startup.

## Included

- Theme: onedark, black background
- LSP: TS, Deno, Rust, Zig, Go, Python, Lua, HTML/CSS, JSON, YAML, SQL, Bash, Docker, Java, C/C++, CMake, XML, Nix, PHP, C#, Tailwind, Emmet
- Formatters: prettier, stylua, rustfmt, zigfmt, gofmt, black, google-java-format, clang-format, php-cs-fixer
- Plugins: harpoon, flash, lazygit, diffview, trouble, todo-comments, rainbow brackets, image.nvim, import-cost, nvim-ts-autotag, colorizer, markdown-preview, kulala
- Keymaps: `K` hover/type info, `<leader>ih` buffer inlay hints, `<leader>iH` global inlay hints, `<leader>gg` lazygit, `<leader>ha` harpoon add, `s` flash jump, `<leader>cc` Codex, `<leader>co` Opencode, `<leader>fm` format, `<leader>xx` diagnostics

## Credits

This repo provides the config, keymaps, setup scripts, and platform glue.

Upstream pieces:

- [NvChad](https://github.com/NvChad/NvChad) v2.5
- [mason.nvim](https://github.com/williamboman/mason.nvim) for LSP and formatter installs on non-NixOS systems
- [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for syntax and parsing
- [image.nvim](https://github.com/3rd/image.nvim) for inline image support
