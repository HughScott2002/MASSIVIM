# Changelog

## Unreleased

### Fixed

- File ownership: chown'd `lua/` files owned by root to hugh:users.
- `lua/chadrc.lua`: Added missing WSL Mason packages (zls, clangd, deno, phpactor, nil, clang-format, php-cs-fixer).
- `lua/plugins/init.lua`: Guarded `opts.sources` with `or {}` to prevent nil error on `nvim-cmp`.
- `lua/plugins/init.lua`: Removed `FixCursorHold.nvim` dependency (no-op on Neovim 0.11+).
- `lua/plugins/init.lua`: Removed trailing empty string from `window_overlap_clear_ft_ignore`.
- `lua/configs/lspconfig.lua`: Added comment noting roslyn_ls requires .NET SDK on WSL.
