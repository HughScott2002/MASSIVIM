# MASSIVIM

[![NixOS](https://img.shields.io/badge/NixOS-ready-5277C3?logo=nixos&logoColor=white)](https://nixos.org/)
[![Neovim](https://img.shields.io/badge/Neovim-0.12+-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![NvChad](https://img.shields.io/badge/NvChad-v2.5-6D57A8)](https://nvchad.com/)
[![Lua](https://img.shields.io/badge/Lua-config-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)

Portable NvChad config. NixOS first. Works elsewhere with Neovim 0.12+.

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

Back up ~/.config/nvim. Clone the repo. Run ~/.config/nvim/setup.sh (it also pre-installs plugins and treesitter parsers). Open nvim once so Mason auto-installs LSPs and formatters.

Install needed runtimes yourself: Rust/rustfmt, Zig/zigfmt, Go/gofmt, Java, .NET, and PHP. setup.sh prints a runtime check at the end showing what's missing.

Before finishing, check OS package names, Neovim version, PATH, language runtimes, and Mason tools that still need system runtimes. Fix launch blockers.
```

## Quick Start

> Warning: NixOS is the main target. Non-NixOS needs Neovim 0.12+ and some runtimes outside Mason.

Icons need a [Nerd Font](https://www.nerdfonts.com) set in your terminal on all platforms.

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
    unstable.neovim # >= 0.12
    git
    gcc
    gnumake
    ripgrep
    fd
    lazygit
    unstable.nodejs
    unzip
    curl
    unstable.tree-sitter # native CLI >= 0.26.1
    jdk21_headless
    dotnet-sdk_10

    # LSPs
    nil
    lua-language-server
    typescript-language-server
    typescript # Astro TypeScript SDK <=6
    unstable.vscode-langservers-extracted # tested complete HTML/JSON/CSS bundle
    tailwindcss-language-server
    emmet-ls
    unstable.flutterPackages.v3_41 # includes matching Dart; tested with locked Flutter projects
    unstable.astro-language-server
    unstable.sourcekit-lsp
    unstable.swift
    unstable.qt6.qtdeclarative # qmlls
    unstable.wgsl-analyzer
    unstable.powershell
    unstable.powershell-editor-services
    unstable.kotlin-language-server
    unstable.terraform-ls
    unstable.glsl_analyzer
    unstable.ruby-lsp
    unstable.taplo
    unstable.mesonlsp
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
    texlab
    lemminx
    deno
    phpactor
    jdt-language-server
    roslyn-ls

    # Java debug/test
    vscode-extensions.vscjava.vscode-java-debug
    vscode-extensions.vscjava.vscode-java-test

    # Debuggers (lldb-dap for Rust/C/C++, Delve for Go, debugpy for Python)
    lldb
    delve
    (python3.withPackages (ps: [ ps.debugpy ]))

    # Formatters and linters
    stylua
    prettier
    google-java-format
    rustfmt
    gofumpt
    gotools # provides goimports
    golangci-lint
    ruff
    nixfmt
    statix
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

Manual runtimes: Rust/rustfmt, Zig/zigfmt, Go/gofmt, Java, .NET, PHP. `setup.sh` prints a runtime check at the end showing what's missing.

## How It Works

### NixOS

LSP servers and formatters are defined in `configuration.nix`, so Mason stays disabled.

### Everything Else

Run `setup.sh` once — it installs system dependencies and pre-installs plugins plus Tree-sitter parsers; failures exit nonzero. On first launch Mason auto-installs the LSPs and formatters (and keeps retrying missing ones on later launches, so tools appear once their language runtime is installed).

### C / C++

clangd gets its language standard from the project, not from the editor, in this order:

1. `compile_commands.json` (CMake: `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`; Meson emits it by default)
2. `compile_flags.txt` in the project root, one flag per line
3. otherwise `~/.config/clangd/config.yaml`, which has separate `If: PathMatch` fragments for `.c` (`gnu17`) and `.cpp`/headers (`c++23`)

For a C project without a build system, drop this next to your sources:

```text
-std=gnu17
-Wall
-Wextra
```

That file also settles the `.h` question — clangd treats a bare header as C++ by default, so a C project should add `-xc`.

Debugging uses `lldb-dap` through the existing DAP keymaps (`<leader>db`, `<leader>dc`, `<leader>du`).

## WSL2 Notes

WSL2 needs a little extra setup because package availability is uneven.

### 1. Install Neovim 0.12+

The pinned nvim-treesitter main implementation requires Neovim 0.12+ and the native tree-sitter CLI 0.26.1+ for parser installation. Older Neovim versions fail with an upgrade message.

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

## Verify configuration changes

Run the headless smoke suite as the normal user after changing MASSIVIM:

```bash
tests/smoke.sh
```

It uses a temporary XDG config directory and never changes your live config.

- Theme: onedark, black background
- LSP: TS, Deno, Rust, Zig, Go, Python, Lua, HTML/CSS, JSON, YAML, SQL, Bash, Docker, Java, C/C++, CMake, XML, Nix, PHP, C#, Tailwind, Emmet, LaTeX
- Formatters: prettier, stylua, rustfmt, zigfmt, goimports, gofumpt, ruff, nixfmt, google-java-format, clang-format, php-cs-fixer
- Linters: golangci-lint (Go), ruff (Python), statix (Nix)
- Debuggers: lldb-dap (Rust/C/C++), Delve (Go), debugpy (Python)
- Tests: Neotest with Java, Go, and Python adapters
- Rust: rust-analyzer runs Clippy on save, `<leader>ca` applies code actions
- Plugins: harpoon, flash, lazygit, diffview, trouble, todo-comments, rainbow brackets, image.nvim, nvim-ts-autotag, catgoose colorizer, render-markdown, markdown-preview, kulala, clangd_extensions
- Keymaps: `K` hover/type info, `<leader>ca` code action, `<leader>ih` buffer inlay hints, `<leader>iH` global inlay hints, `<leader>ch` C/C++ source/header, `<leader>gg` lazygit, `<leader>ha` harpoon add, `s` flash jump, `<leader>cc` Codex, `<leader>co` Opencode, `<leader>fm` format, `<leader>xx` diagnostics

## Credits

This repo provides the config, keymaps, setup scripts, and platform glue.

Upstream pieces:

- [NvChad](https://github.com/NvChad/NvChad) v2.5
- [mason.nvim](https://github.com/williamboman/mason.nvim) for LSP and formatter installs on non-NixOS systems
- [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for syntax and parsing
- [image.nvim](https://github.com/3rd/image.nvim) for inline image support

## Language coverage and parser maintenance

See [language-coverage.md](docs/language-coverage.md) for mappings, semantic tools,
explicit formatters, and platform/grammar limits. Neovim 0.12+ is required on
NixOS, WSL, and other systems. Upgrade via your package manager or the official
Neovim releases before running setup. Parser installation needs the **native**
Tree-sitter CLI >=0.26.1, Python 3, Git, Node, a C compiler, curl and tar.
`setup.sh` uses Homebrew's native CLI or a pinned Cargo installation into
`~/.local`; it does not use the npm CLI wrapper. Put `~/.local/bin` on PATH.

Run `:MassivimParsers` to install/update the declared list after upgrading.
The supported build hook waits for completion and fails on any missing parser.
Startup uses installed parsers offline and reports missing ones once; it never
retries downloads on each launch. Parser sources are pinned by the plugin lock
and the two small patches in `patches/`; `scripts/prepare-grammars.py` applies
those patches in the user's cache, without modifying downloaded plugins.

On NixOS, the tested channel revision was `151fa4e8ddfd` (26.11pre1086391):
Tree-sitter 0.26.11 and vscode-langservers-extracted 1.126.04524. The latter
fixes the missing bundled HTML/JSON/CSS chunks in stable's 1.106.27818.
Other supported paths use Mason for the declared language tools. SDKs still
come from their owners: Dart/Flutter SDK, Swift/SourceKit and Apple SDKs where
needed, Qt/QML, Ruby/Bundler, Java, .NET, TeX Live (`latexmk`, XeLaTeX), and
Rustup. LaTeX uses `texlab` plus VimTeX; `latexmk` runs XeLaTeX with SyncTeX
and writes PDFs to `build/`, opened with `zathura` when it is installed. Actual
WSL installation needs a WSL host to verify; Linux configuration tests alone do
not prove it.

For Rustup, keep Cargo, rustc, rustfmt, Clippy, rust-analyzer and rust-src on
one toolchain. For example: `rustup component add rust-analyzer rust-src clippy
rustfmt --toolchain stable`. Check `rustup show` and `rust-analyzer --version`;
an analyzer shim falling back to a Nix analyzer is not a coherent toolchain.
Project overrides take precedence; do not overwrite them across repositories.
For native projects, open Neovim in the project's declared development shell:
`nix develop -c zsh`, then `nvim`. Zsh keeps your usual prompt and completion.
The editor does not invent global compiler flags, include paths, or SDKs.

Regression checks (run as the configuration's owner):

```sh
bash tests/smoke.sh
python3 tests/lsp-probe.py
MASSIVIM_MANIFEST="$PWD/tests/fixtures/coverage/manifest.json" \
MASSIVIM_OUTPUT=/tmp/massivim-coverage.json \
  bash tests/isolated.sh '+luafile tests/coverage.lua' '+qa!'
bash tests/isolated.sh '+luafile tests/regression.lua' '+qa!'
```

The isolated harness copies mutable plugin/parser data, disables modelines and
installation, and gives each run separate XDG config/data/state/cache. Set
`MASSIVIM_COLD=1` to omit parser data for an explicit cold installation check;
set `MASSIVIM_LOG_DIR` to retain fresh state logs. The coverage scanner never
saves source files and separates top-level errors from injected examples.
