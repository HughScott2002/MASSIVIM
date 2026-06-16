# Agent Context

Reference material moved out of `AGENTS.md`. Use this when a task touches setup, keymaps, or release docs.

For the full user-facing install instructions and NixOS package blocks, see `README.md`.

## Quick Start

```bash
git clone https://github.com/HughScott2002/MASSIVIM.git ~/.config/nvim
nvim  # lazy.nvim auto-installs plugins, Mason auto-installs tools
```

NixOS users should install the package block from `README.md` before launching `nvim`. Mason is disabled there because the system owns LSP and formatter binaries.

## Key Mappings

| Key | Action |
|---|---|
| `<leader>cc` | Toggle Codex (AI coding) |
| `<leader>co` | Toggle Opencode (AI coding) |
| `<leader>gg` | LazyGit |
| `<leader>fm` | Format file |
| `<leader>xx` | Diagnostics list (Trouble) |
| `<leader>ss` | Flash jump |
| `s` | Flash quick jump to any visible character |
| `jk` | Escape insert mode |

See `lua/mappings.lua` for the full list.

## Manual WSL Deps

These tools must be installed separately and are not handled by Mason:

- `.NET SDK` for `roslyn_ls`
- `Zig` for `zigfmt`
- Rust toolchain for `rustfmt`

## Release

```bash
./release.sh [patch|minor|major]
```
