# Changelog

## v1.2.0 — 2026-06-27

### Added

- `lua/configs/lspconfig.lua`: Added `K` hover mapping for LSP buffers so Rust and other LSPs can show inferred type/info on demand.

## v1.1.0 — 2026-06-16

### Fixed

- File ownership: chown'd `lua/` files owned by root to hugh:users.
- `lua/chadrc.lua`: Added missing WSL Mason packages (zls, clangd, deno, phpactor, nil, clang-format, php-cs-fixer).
- `lua/plugins/init.lua`: Guarded `opts.sources` with `or {}` to prevent nil error on `nvim-cmp`.
- `lua/plugins/init.lua`: Removed `FixCursorHold.nvim` dependency (no-op on Neovim 0.11+).
- `lua/plugins/init.lua`: Removed trailing empty string from `window_overlap_clear_ft_ignore`.
- `lua/configs/lspconfig.lua`: Added comment noting roslyn_ls requires .NET SDK on WSL.
