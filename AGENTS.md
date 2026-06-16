# MASSIVIM

Portable NvChad-based Neovim config. Works on NixOS and WSL.

- On NixOS: LSPs, formatters, and tools come from system packages. Keep the README copy-paste package block current when dependencies change.
- AI coding CLIs are optional. Document them separately as `unstable.*` packages and explain that only those named packages come from `nixos-unstable`.
- On WSL (non-NixOS): Mason auto-installs LSPs and formatters on first launch

## Quick start

```bash
git clone https://github.com/HughScott2002/MASSIVIM.git ~/.config/nvim
nvim  # lazy.nvim auto-installs plugins, Mason auto-installs tools
```

NixOS users should install the package block from `README.md` before launching `nvim`. Mason is disabled there because the system owns LSP and formatter binaries.

## Key mappings

| Key | Action |
|---|---|
| `<leader>cc` | Toggle Codex (AI coding) |
| `<leader>co` | Toggle Opencode (AI coding) |
| `<leader>gg` | LazyGit |
| `<leader>fm` | Format file |
| `<leader>xx` | Diagnostics list (Trouble) |
| `<leader>ss` | Flash jump |
| `s` | Flash — quick jump to any visible character |
| `jk` | Escape insert mode |

See `lua/mappings.lua` for the full list.

## Manual WSL deps

These tools must be installed separately (not in Mason):

- **.NET SDK** — required by `roslyn_ls` (C# LSP). Install from https://dotnet.microsoft.com/download
- **Zig** — required by `zigfmt` formatter. Install from https://ziglang.org/download
- **Rust toolchain** (`rustfmt`) — install via https://rustup.rs

## Release

```bash
./release.sh [patch|minor|major]
```
