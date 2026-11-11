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

### Language coverage remediation

- Require Neovim 0.12 and native Tree-sitter CLI >=0.26.1; replace the inherited missing `TSInstallAll` hook with bounded, checked installation and explicit offline-safe maintenance.
- Expand grammar coverage and add representative language fixtures, isolated syntax/query scans, actual LSP attachment checks, and stdio lifecycle probes.
- Correct clangd's boolean option and use negotiated position encodings; guard empty custom snippet paths.
- Add optional SDK/language server configuration and explicit-only formatters without expanding formatting on save.
- Detect Metal, JSON Lines, systemd units and named templates; validate JSON Lines independently per record, without exposing source text in diagnostics.
- Patch pinned Rust safe extern declarations and Bash single-dash tests; resolve GitHub Actions injections by explicit shell and defaults rather than interpreting PowerShell as Bash.
- Document remaining parser/platform limits and the corrected Nix server bundle. Intentional malformed source fixtures remain unchanged.
- Add `texlab` LSP and VimTeX config; XeLaTeX builds go to `build/` with SyncTeX.

### Added

- Go: gopls gofumpt/staticcheck settings, `goimports` + `gofumpt` formatting, `golangci-lint` through nvim-lint, Delve debugging through nvim-dap-go, and `neotest-golang`.
- Python: Ruff formatting/linting, debugpy through nvim-dap-python, `neotest-python`, and venv-selector on `<leader>cv`.
- Nix: `nixfmt` formatting and `statix` linting.
- Rust: Clippy-on-save settings on the current rust-analyzer schema, inlay hints, proc macros, and `<leader>ca` code actions.
- `render-markdown.nvim` for in-buffer Markdown rendering while keeping browser preview.

### Changed

- Replaced the stale `norcalli/nvim-colorizer.lua` with the maintained `catgoose/nvim-colorizer.lua`.
- Removed the archived `import-cost.nvim` plugin.
- clangd now advertises nvim-cmp completion capabilities without setting a global language standard.

### Fixed

- Keep `init.lua` as a portable Lua file instead of a machine-specific Nix store symlink.
- Missing Go, Python, or Nix linters are skipped instead of raising ENOENT from `BufWritePost` and breaking the write.
- C files no longer inherit C++ settings. The global `~/.config/clangd/config.yaml` applied `-std=c++23` to every file, so clangd rejected `.c` files with `invalid argument '-std=c++23' not allowed with 'C'` and ran `modernize-*` C++ checks (for example "use `std::print` instead of `printf`") on C code. The config is now split into `If: PathMatch` fragments per language.
- `lua/configs/lspconfig.lua`: clangd now declares explicit `root_markers` (`.clangd`, `.clang-tidy`, `.clang-format`, `compile_commands.json`, `compile_flags.txt`, `CMakeLists.txt`, `Makefile`, `meson.build`, `build.ninja`, `.git`) instead of inheriting defaults.
- Treesitter highlighting now actually attaches: the nvim-treesitter main branch dropped the `highlight = { enable = true }` module, so a `FileType` autocmd now calls `vim.treesitter.start()` and sets the treesitter `indentexpr`.
- Parser installs no longer crash on Neovim 0.11 (polyfill for the 0.12-only `vim.list.unique`). Added `gomod`, `gowork`, and `gosum` parsers; `jsonc` files reuse the `json` parser.

### Added

- `p00f/clangd_extensions.nvim` for AST, symbol info, and memory usage views (the same companion plugin LazyVim's `lang.clangd` extra uses).
- `<leader>ch` switches between a C/C++ source file and its header.
- C/C++ DAP configurations using the existing `lldb-dap` adapter.

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