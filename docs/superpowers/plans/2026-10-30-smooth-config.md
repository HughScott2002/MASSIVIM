# Smooth MASSIVIM Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make MASSIVIM reliable, reference-backed, and regression-tested across its supported language workflows.

**Architecture:** Keep NvChad as the editor distribution and port portable behaviour—not framework-specific LazyVim/AstroNvim code. A shell-based headless smoke suite will test runtime configuration; tool installation remains declarative on NixOS and Mason-backed elsewhere.

**Tech Stack:** Neovim 0.11+, NvChad v2.5, lazy.nvim, nvim-lspconfig, Conform, nvim-lint, nvim-dap, Neotest, NixOS packages.

**Spec:** `docs/superpowers/specs/2026-10-30-smooth-config-design.md`

## Global Constraints

- Support NixOS system tools and non-NixOS Mason installation.
- Do not migrate to blink.cmp or change existing motion mappings in this scope.
- Write each regression check before the configuration it protects.
- Verify headlessly as `hugh`; no test may use or modify the live checkout.
- Commit each independently testable stage with SSH signing and no AI attribution.

## Review Focus

- A non-modifiable buffer must save without a whitespace-autocmd error.
- Markdown trailing spaces must survive because they encode hard line breaks.
- First use of each lazy command/key must load the matching plugin.
- An unavailable formatter/linter must degrade without breaking a write.
- NixOS and Mason paths must specify equivalent tool names where possible.

---

### Task 1: Establish a headless config smoke suite

**Files:**
- Create: `tests/smoke.sh`
- Create: `tests/fixtures/`
- Modify: `README.md`

- [ ] Write failing smoke checks for Lua loading, lazy Neotest availability, Rust analyzer settings, and safe writes.
- [ ] Run `sudo -u hugh -H tests/smoke.sh` and confirm the current configuration fails for known defects.
- [ ] Implement the minimal portable test harness using a temporary `XDG_CONFIG_HOME`, temporary files, and headless Neovim.
- [ ] Re-run the smoke suite and preserve its failure output for each subsequent red/green cycle.
- [ ] Commit the test harness.

### Task 2: Fix observed core configuration defects

**Files:**
- Modify: `lua/autocmds.lua`
- Modify: `lua/configs/lspconfig.lua`
- Modify: `lua/plugins/init.lua`
- Modify: `lua/options.lua`
- Modify: `lua/mappings.lua`
- Test: `tests/smoke.sh`

- [ ] Add failing smoke cases for non-modifiable writes, Markdown hard breaks, Neotest lazy loading, Rust analyzer `check` schema, diagnostic timing, and the inert `path` source.
- [ ] Implement guarded, opt-in trailing-whitespace normalization; correct the Rust analyzer schema; give Neotest explicit lazy triggers and mappings; remove the nonexistent cmp source; configure diagnostics after NvChad initializes; remove the stale global indentation assumption.
- [ ] Run focused smoke cases until green, then run the entire suite.
- [ ] Commit the core reliability stage.

### Task 3: Add project-aware indentation and schemas

**Files:**
- Modify: `lua/options.lua`
- Modify: `lua/autocmds.lua`
- Modify: `lua/configs/lspconfig.lua`
- Modify: `lua/plugins/init.lua`
- Modify: `lazy-lock.json`
- Test: `tests/smoke.sh`

- [ ] Add failing fixtures for `.editorconfig`, JSON SchemaStore resolution, and YAML SchemaStore resolution.
- [ ] Enable project editorconfig support, preserve language defaults only when a project does not set them, and add portable SchemaStore configuration for jsonls and yamlls.
- [ ] Verify schemas load and no Lua helper from LazyVim/AstroNvim is referenced.
- [ ] Commit the formatting-and-schema stage.

### Task 4: Add reference-backed Go, Python, and Nix workflows

**Files:**
- Modify: `lua/configs/lspconfig.lua`
- Modify: `lua/configs/conform.lua`
- Modify: `lua/plugins/init.lua`
- Modify: `lua/chadrc.lua`
- Modify: `README.md`
- Modify: `/etc/nixos/configuration.nix` (separate NixOS repository commit)
- Test: `tests/smoke.sh`

- [ ] Add failing config checks for Go formatter/linter/DAP/test declarations, Python Ruff/debug/test/venv declarations, and Nix formatter/linter declarations.
- [ ] Add only the portable plugin wiring and corresponding Mason package names; update the README NixOS block with tool packages.
- [ ] Add required NixOS packages (`gofumpt`, `goimports`, `golangci-lint`, `delve`, `ruff`, `debugpy`, `nixfmt`, `statix`) and run `sudo nixos-rebuild build` before its separate signed commit.
- [ ] Verify real Go, Python, and Nix fixtures headlessly as `hugh`; verify tool executables resolve after the Nix build/activation path.
- [ ] Commit MASSIVIM and NixOS changes separately.

### Task 5: Complete Rust and C/C++ workflow gaps

**Files:**
- Modify: `lua/configs/lspconfig.lua`
- Modify: `lua/plugins/init.lua`
- Modify: `lua/configs/conform.lua`
- Modify: `lua/chadrc.lua`
- Modify: `README.md`
- Test: `tests/smoke.sh`

- [ ] Add failing Rust smoke coverage proving no invalid rust-analyzer settings and Clippy diagnostics appear after save; add C/C++ clangd comparator coverage.
- [ ] Add portable Rust code-action/test integration and Cargo.toml support only where it does not require LazyVim helpers; add clangd cmp score integration if compatible with nvim-cmp.
- [ ] Verify a real Cargo fixture and existing C/C++ smoke fixture as `hugh`.
- [ ] Commit the Rust/C/C++ stage.

### Task 6: Replace or remove unhealthy plugins

**Files:**
- Modify: `lua/plugins/init.lua`
- Modify: `lua/mappings.lua`
- Modify: `lazy-lock.json`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Test: `tests/smoke.sh`

- [ ] Add failing checks that every configured completion source has a provider and each replacement command/key loads.
- [ ] Remove archived `import-cost.nvim`; replace the stale colorizer with maintained `catgoose/nvim-colorizer.lua`; add `render-markdown.nvim` without removing browser preview.
- [ ] Verify startup time, Markdown rendering, color highlighting, and existing preview mapping.
- [ ] Commit the plugin-maintenance stage.
