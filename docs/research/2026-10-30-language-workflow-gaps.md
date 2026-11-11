# Language-development workflow gap assessment — 2026-10-30

**Scope.** This is a read-only assessment of the live MASSIVIM checkout at
`/home/hugh/.config/nvim`, measured against first-party repositories and
upstream documentation current on 2026-10-30. “Current workflow” below means
behaviour explicitly implemented or documented by a project's own source; it
is not a popularity ranking or a recommendation to migrate distributions.

## Executive assessment

MASSIVIM is already a strong, portable NvChad v2.5 language setup: it has LSPs
for all requested languages, Treesitter parsers, format-on-save, linting for
Go/Python/Nix, schemas for JSON/YAML, and DAP plus Neotest for Go/Python. The
configuration deliberately keeps NixOS tooling system-owned and supports
Mason elsewhere. [Live LSP list and settings](../../lua/configs/lspconfig.lua#L49-L273),
[live formatter policy](../../lua/configs/conform.lua#L1-L39),
[live tooling policy](../../README.md#L83-L129), and
[live non-Nix policy](../../README.md#L170-L189).

The material gaps are therefore *integration and coverage*, not a wholesale
framework deficiency:

1. **Mason provisioning is not reproducibly declared in this checkout.**
   NvChad v2.5's Mason defaults skip adding Mason's bin directory to `PATH` and
   do not include an `ensure_installed` list; MASSIVIM itself declares no
   Mason-tool installer or package list. That contradicts the README promise
   that first launch installs every required LSP/formatter/debugger on
   non-Nix systems. [NvChad Mason v2.5 source](https://raw.githubusercontent.com/NvChad/NvChad/v2.5/lua/nvchad/configs/mason.lua),
   [live plugin specs](../../lua/plugins/init.lua#L1-L535),
   [README claim](../../README.md#L185-L189), and
   [Mason's official description of its install/PATH behaviour](https://github.com/mason-org/mason.nvim#introduction).
2. **Go's deliberately enabled code lenses lack a visible/refresh/run
   workflow.** The gopls configuration enables seven lens categories, but no
   mapping invokes `vim.lsp.codelens.refresh()` or `.run()`. LazyVim's own LSP
   integration supplies both when code lenses are enabled; AstroCommunity's Go
   pack also enables generate/test/tidy lenses. [Live gopls settings](../../lua/configs/lspconfig.lua#L118-L149),
   [LazyVim LSP source](https://raw.githubusercontent.com/LazyVim/LazyVim/main/lua/lazyvim/plugins/lsp/init.lua),
   [AstroCommunity Go pack](https://raw.githubusercontent.com/AstroNvim/astrocommunity/main/lua/astrocommunity/pack/go/init.lua).
3. **Semantic tokens are disabled globally by NvChad v2.5.** The base
   `on_init` removes the provider even on Neovim 0.11; this suppresses richer
   semantic highlighting where servers supply it. In particular, current
   lspconfig says gopls no longer advertises tokens by default and enables
   them client-side to retain the previous experience. [NvChad v2.5 LSP
   source](https://raw.githubusercontent.com/NvChad/NvChad/v2.5/lua/nvchad/configs/lspconfig.lua),
   [current lspconfig gopls source](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/gopls.lua).
4. **Testing/debugging coverage stops short of Rust, C/C++, and Nix.** DAP
   has Go, Python, Rust and C/C++ launch support, but Neotest registers only
   Java/Go/Python and has no “debug nearest test” binding. Neotest officially
   documents Rust, C++ (gtest/ctest), and Nix adapters and its DAP strategy.
   [Live DAP/Neotest specs](../../lua/plugins/init.lua#L305-L443),
   [Neotest official adapter and DAP strategy list](https://github.com/nvim-neotest/neotest#supported-runners).
5. **The Nix server is `nil_ls`, not `nixd`.** This is not inherently wrong,
   but it misses nixd's current upstream lspconfig integration and flake-root
   detection. Evaluate it as an opt-in replacement only, because server choice
   and evaluator settings are user/project-specific. [Live server list](../../lua/configs/lspconfig.lua#L49-L76),
   [nixd lspconfig source](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/nixd.lua).

## What is already high quality

| Area | Current live capability | Primary-source comparison |
|---|---|---|
| Go | `gopls` enables unimported completion, placeholders, gofumpt, staticcheck, selected analyses, extensive code lenses and inlay hints; Conform runs `goimports` then `gofumpt`; `golangci-lint`, Delve, and Neotest Go are configured. [Live config](../../lua/configs/lspconfig.lua#L118-L149), [formatter/linter/DAP/test config](../../lua/configs/conform.lua#L16-L20), [live plugin config](../../lua/plugins/init.lua#L9-L37) | This aligns closely with AstroCommunity's official Go pack, which enables gopls analyses/lenses/hints and uses `goimports` with LSP formatting last. [AstroCommunity Go pack](https://raw.githubusercontent.com/AstroNvim/astrocommunity/main/lua/astrocommunity/pack/go/init.lua) |
| Python | Pyright, Ruff lint + format/import organization, debugpy fallback logic, venv-selector, and pytest Neotest with DAP settings are present. [Live config](../../lua/configs/lspconfig.lua#L49-L76), [live formatter/linter/DAP/test config](../../lua/configs/conform.lua#L16-L20), [live plugin config](../../lua/plugins/init.lua#L9-L37) | Current lspconfig's Pyright defaults recognize standard project roots and include commands to organize imports/set interpreter paths, which is compatible with the existing venv selector approach. [lspconfig Pyright source](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/pyright.lua) |
| Rust | `rust-analyzer` runs Clippy on save, enables proc macros and useful inlay hints; `rustfmt` and LLDB DAP launches are configured. [Live RA/DAP config](../../lua/configs/lspconfig.lua#L151-L178), [live formatter/DAP config](../../lua/configs/conform.lua#L16-L24) | Rust-analyzer's official configuration documentation confirms these are LSP-supplied settings, including proc-macro and Cargo build-script support. [rust-analyzer configuration](https://raw.githubusercontent.com/rust-lang/rust-analyzer/master/docs/book/src/configuration.md) |
| C/C++ | Clangd has background indexing, clang-tidy, IWYU, project-root markers, source/header switching, treesitter parsers, clang-format, and LLDB DAP. [Live config](../../lua/configs/lspconfig.lua#L217-L255), [live plugins](../../lua/plugins/init.lua#L50-L58) | lspconfig identifies `compile_commands.json` as the key clangd input and supplies the same source/header switch capability. [lspconfig clangd source](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/clangd.lua) |
| Nix | `nil_ls`, nixfmt, statix, a Nix parser, and NixOS system-package instructions are present. [Live config](../../lua/configs/lspconfig.lua#L49-L76), [live formatter/linter/parser config](../../lua/configs/conform.lua#L16-L20), [live plugin config](../../lua/plugins/init.lua#L9-L37) | This meets baseline editing/linting/formatting needs without forcing a server change. |
| JSON/YAML | jsonls/yamlls, SchemaStore injection, formatting/validation, curated schema mappings, and parsers are present. [Live config](../../lua/configs/lspconfig.lua#L180-L200), [JSON config](../../lua/configs/lspconfig.lua#L257-L273), [live parser list](../../lua/plugins/init.lua#L60-L123) | lspconfig documents schema-to-glob associations and per-file schema modelines for YAML; the current configuration implements the association path. [lspconfig yamlls source](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/yamlls.lua) |
| Completion | NvChad v2.5 supplies nvim-cmp, LuaSnip, and LSP/buffer/path sources; MASSIVIM retains that stack. [NvChad cmp source](https://raw.githubusercontent.com/NvChad/NvChad/v2.5/lua/nvchad/configs/cmp.lua), [live lockfile](../../lazy-lock.json#L2-L62) | nvim-cmp's official configuration recommends LSP capabilities via `cmp_nvim_lsp.default_capabilities()` and supports cmdline path/command completion. [nvim-cmp README](https://raw.githubusercontent.com/hrsh7th/nvim-cmp/main/README.md) |

## Recommendations, in implementation order

These are intentionally compatible with **NvChad v2.5**, Neovim 0.11, NixOS,
and Mason-managed non-Nix installs. They add targeted plugin specs/configuration
rather than adopting LazyVim/AstroNvim or replacing NvChad's core.

### P0 — make non-Nix tools deterministic without touching NixOS ownership

Add a small platform gate which leaves NixOS `PATH = "skip"` and system
packages alone, but on non-Nix hosts declares an explicit `ensure_installed`
set for every LSP, formatter, linter, DAP adapter and test runtime that
MASSIVIM promises. Use Mason package names (for example `gopls`, `pyright`,
`rust-analyzer`, `clangd`, `nil`, `json-lsp`, `yaml-language-server`,
`delve`, `debugpy`, `ruff`, `golangci-lint`, `nixfmt`, `statix`) and use
`mason-tool-installer.nvim` or an equivalent idempotent registry loop.

Mason is intended to manage LSP, DAP, linter, and formatter executables in one
interface, puts them beneath Neovim's data directory, and normally adds its
bin directory to Neovim's `PATH`; its own README also says setup should not be
lazy-loaded. [Mason README](https://github.com/mason-org/mason.nvim#introduction),
[Mason setup guidance](https://github.com/mason-org/mason.nvim#installation--usage).
The platform gate is essential: NvChad v2.5 intentionally sets `PATH = "skip"`,
and the project explicitly says NixOS owns the binaries. [NvChad Mason source](https://raw.githubusercontent.com/NvChad/NvChad/v2.5/lua/nvchad/configs/mason.lua),
[MASSIVIM Nix policy](../../README.md#L181-L189).

### P1 — finish the LSP feedback loop

1. Add buffer-local mappings to **refresh/display and run code lenses** where
   `textDocument/codeLens` is supported; refresh on attach, buffer enter, and
   save/insert-leave. This realizes the gopls lens configuration rather than
   merely requesting it. LazyVim's first-party implementation is an appropriate
   compact reference. [LazyVim LSP implementation](https://raw.githubusercontent.com/LazyVim/LazyVim/main/lua/lazyvim/plugins/lsp/init.lua).
2. Preserve semantic tokens on Neovim 0.11+ by overriding only NvChad's
   global `on_init` behaviour (or by clearing it for semantic-capable targeted
   servers). Verify it with `:Inspect`/`:LspInfo` after implementation. Do not
   alter legacy compatibility blindly: the existing v2.5 source disables them
   intentionally. [NvChad LSP source](https://raw.githubusercontent.com/NvChad/NvChad/v2.5/lua/nvchad/configs/lspconfig.lua),
   [gopls token note](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/gopls.lua).
3. Add normal LSP ergonomics that are currently absent or undiscoverable in
   the custom map file: references, implementation, type definition, document
   symbols, workspace symbols, rename, signature help, diagnostic next/prev,
   and a diagnostic float. NvChad already supplies declaration/definition/type
   definition and workspace mappings; retain them and add only unbound actions.
   [NvChad v2.5 LSP mappings](https://raw.githubusercontent.com/NvChad/NvChad/v2.5/lua/nvchad/configs/lspconfig.lua).

### P1 — complete test and debugger coverage

* Add a Neotest Rust adapter (either the documented Rust adapter or
  rustaceanvim's LSP-driven integration); add C++ gtest/ctest only when those
  runners are used; add Nix flake-check/nix-unit support only when relevant.
  These are all officially enumerated by Neotest, so no speculative adapter is
  needed. [Neotest adapter list](https://github.com/nvim-neotest/neotest#supported-runners).
* Map **debug nearest test** to `neotest.run.run({ strategy = "dap" })`, and
  add test stop, attach, output panel, and optional watch commands. Neotest
  documents each of those consumers and the DAP strategy. [Neotest usage and
  consumers](https://github.com/nvim-neotest/neotest#usage).
* Add DAP terminate/restart/continue-to-cursor/conditional-breakpoint/logpoint
  and REPL/evaluate mappings. nvim-dap explicitly supports those features and
  says its language extensions are preferred over manual configurations where
  available. [nvim-dap README](https://raw.githubusercontent.com/mfussenegger/nvim-dap/master/README.md).
* Keep **LLDB-DAP** on NixOS (already supplied by `lldb`); optionally use
  CodeLLDB only on non-Nix hosts where it is installed declaratively through
  Mason. AstroCommunity's official Rust pack shows a guarded CodeLLDB setup,
  but this is an enhancement, not a required replacement. [AstroCommunity Rust
  pack](https://raw.githubusercontent.com/AstroNvim/astrocommunity/main/lua/astrocommunity/pack/rust/init.lua).

### P2 — polish language-specific workflows

* **Nix:** trial `nixd` behind an opt-in server selector; add it to the NixOS
  package block only if chosen, and map its flake-aware evaluator options from
  the user's flake convention. The upstream lspconfig integration is
  flake-root aware, but it intentionally contains no universal evaluator
  configuration. [nixd lspconfig source](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/nixd.lua).
* **Rust:** add `Cargo.toml` dependency completion/actions (for example the
  maintained crates workflow used by AstroCommunity) only if dependency-edit
  ergonomics justify another plugin. Existing RA + Clippy + rustfmt is already
  sound. [AstroCommunity Rust pack](https://raw.githubusercontent.com/AstroNvim/astrocommunity/main/lua/astrocommunity/pack/rust/init.lua).
* **Completion:** retain nvim-cmp for NvChad v2.5 stability, but add
  `cmp-cmdline` plus path/cmdline sources and configure LSP capabilities with
  nvim-cmp's supported helper if an audit shows the current manual capability
  table omits needed fields. Blink is not a low-risk “current default” here:
  its official README says v2 is actively developed with breaking changes and
  requires `blink.lib`; v1 is the stable branch. [nvim-cmp recommendation](https://raw.githubusercontent.com/hrsh7th/nvim-cmp/main/README.md),
  [blink README](https://raw.githubusercontent.com/Saghen/blink.cmp/main/README.md).

## Suggested acceptance matrix

Run this once on NixOS with only the README package block and once on a clean
non-NixOS installation after Mason provisioning:

| Workflow | Evidence of success |
|---|---|
| Go | `gopls` attaches in a `go.work`/`go.mod` workspace; an unimported symbol completes; `goimports` + `gofumpt` format; staticcheck diagnostic appears; a test runs, debugs, and a gopls code lens is visible/runnable. |
| Python | Project venv selection changes interpreter-dependent diagnostics; Ruff formats and organizes imports; pytest nearest/file run and nearest test debugs. |
| Rust | RA attaches to a Cargo workspace; Clippy reports on save; inlay hints toggle; rustfmt runs; a Rust test runs/debugs; LLDB launch works. |
| C/C++ | Clangd reads `compile_commands.json`; source/header switching works; clang-tidy diagnostics appear; CMake/CTest or gtest run/debug works if enabled. |
| Nix | nil_ls or selected nixd attaches to a flake; nixfmt and statix work; relevant test/flake-check workflow runs if enabled. |
| JSON/YAML | Schema completion/validation occurs for `package.json`, GitHub workflow, Compose, and a YAML `$schema` modeline. lspconfig documents modelines and root-relative schema associations. [yamlls source](https://raw.githubusercontent.com/neovim/nvim-lspconfig/master/lsp/yamlls.lua) |
| Portability | `:checkhealth mason`, `:checkhealth vim.lsp`, and `tests/smoke.sh` pass; test the documented required runtimes on non-Nix. [Mason requirements](https://github.com/mason-org/mason.nvim#requirements), [MASSIVIM smoke instructions](../../README.md#L276-L286) |

## Source inventory

All external links above are upstream project repositories/documentation (first
party). Local citations refer to the live, read-only MASSIVIM configuration at
`/home/hugh/.config/nvim` and intentionally identify the exact evidence used.
