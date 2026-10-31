# Smooth MASSIVIM Design

## Intent

Make MASSIVIM reliable first, then bring its Go, Python, Nix, Rust, and
JSON/YAML workflows to the capabilities actually implemented by the reference
configurations studied: LazyVim, AstroNvim, Kickstart.nvim, and NvChad v2.5.

## Goals

- Preserve portable NixOS and non-NixOS/Mason support.
- Fix observed runtime defects before adding capabilities.
- Add only reference-backed language workflows.
- Add executable headless smoke coverage for configuration regressions.
- Keep the live config unchanged until the isolated worktree passes checks.

## Non-goals

- Do not copy LazyVim or AstroNvim framework helpers into NvChad.
- Do not migrate completion from nvim-cmp to blink.cmp in this work.
- Do not change intentional normal-mode mappings (`;`, `s`, `S`) without a
  separate ergonomics decision.
- Do not replace `lldb-dap` with CodeLLDB without a dedicated debugger review.

## Chosen approach

Use native Neovim, Conform, nvim-lspconfig, nvim-lint, nvim-dap, and Neotest
interfaces that correspond to behaviours proven in the reference configs. On
NixOS, tools are added declaratively in `/etc/nixos/configuration.nix`; on
other systems, Mason gets the matching packages where it supports them.

## Constraints

- The global clangd configuration remains language-scoped.
- Existing project configuration takes precedence over editor defaults.
- Tests must run headlessly as user `hugh` and must not modify the live config.
- Each independently verifiable stage commits separately and is SSH-signed.
- Any NixOS package change is verified with `sudo nixos-rebuild build` before
  it is reported complete.

## Source evidence

- LazyVim actual extras: `clangd.lua`, `go.lua`, `python.lua`, `rust.lua`,
  `json.lua`, `yaml.lua`, `nix.lua`, and TypeScript extras.
- AstroNvim actual core: guarded autocmds, editorconfig reapplication,
  Treesitter indent guarding, and lazy-load conventions.
- Kickstart.nvim actual core: idempotent augroups, guarded LSP mappings, and
  headless-safe autocmd patterns.
- NvChad v2.5 actual parent source: config merge behaviour, diagnostics timing,
  existing async path completion, and lazy-plugin triggers.
