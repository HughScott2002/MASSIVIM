# MASSIVIM Changelog

## v1.3.2 — 2026-07-16

- update config — v1.3.2
- Merge pull request #3 from HughScott2002/fix/reproducible-bootstrap
- chore(gitignore): ignore .a5c tool scratch dir
- chore(todo): add Go debugging backlog item
- fix(treesitter): start highlighting and heal installs on 0.11
- Merge pull request #1 from HughScott2002/main
- docs: note Nerd Font requirement in README quick start
- fix: self-healing bootstrap for Mason, treesitter parsers, and DAP

## Unreleased

### Fixed

- Treesitter highlighting now actually attaches: the nvim-treesitter main branch dropped the `highlight = { enable = true }` module, so a `FileType` autocmd now calls `vim.treesitter.start()` and sets the treesitter `indentexpr`.
- Parser installs no longer crash on Neovim 0.11 (polyfill for the 0.12-only `vim.list.unique`). Added `gomod`, `gowork`, and `gosum` parsers; `jsonc` files reuse the `json` parser.

## v1.3.1 — 2026-06-27

### Fixed

- `image.nvim`: disable inline image setup in tmux when `allow-passthrough` is missing, and show a warning instead of crashing on startup.

## v1.3.0 — 2026-06-27

### Added

- Inline inlay hint toggles: `<leader>ih` toggles hints for the current LSP buffer and `<leader>iH` toggles them globally for the session.

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