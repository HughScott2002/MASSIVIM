# Expert Language Workflows Design

## Intent

Give MASSIVIM an explainable, low-friction feedback loop for writing and
debugging intelligent code: completion, navigation, diagnostics, tests,
debugging, builds, and project-aware tasks across Go, Python, Rust, C/C++,
Nix, JSON, and YAML.

## Goals

- Keep NvChad v2.5 and stable `nvim-cmp`; do not make a high-risk Blink
  migration.
- Make non-NixOS setup deterministic through explicit Mason provisioning,
  while NixOS continues to own runtime tools through system packages.
- Expose the LSP feedback loop: semantic tokens where compatible, lenses,
  references, implementations, symbols, rename, signatures, diagnostics, and
  code actions.
- Provide discoverable one-key test and DAP flows: nearest/file/suite test,
  debug nearest, breakpoints, conditional breakpoints, logpoints, continue,
  terminate, REPL, evaluate, and output.
- Match local C++ and Nix projects: CMake presets/Ninja/CTest and
  `nix flake check`/`nix build` tasks.
- Test both supported platform paths headlessly where possible.

## Non-goals

- No migration away from NvChad or nvim-cmp.
- No global default for Meson, Make, Bazel, GoogleTest-only, or a Nix unit-test
  adapter; these are not the local primary workflows.
- Do not replace NixOS `lldb-dap` with CodeLLDB.
- Do not introduce archived adapters or undeclared runtime dependencies.

## Evidence

- Gap assessment: `docs/research/2026-10-30-language-workflow-gaps.md`.
- Local runner assessment: `docs/research/2026-10-30-local-runner-assessment.md`.
- Active C++ projects use CMake presets, Ninja, CTest, GoogleTest/Catch2, and
  LLDB-DAP; Nix projects use flake checks and selected builds.

## Chosen approach

Build a layered workflow with native Neovim/NvChad APIs:

1. **Portable tool ownership:** on non-Nix hosts, install the declared LSP,
   formatter, linter, and DAP tools through Mason. On NixOS, retain `PATH =
   "skip"` and document any additional package requirements.
2. **LSP feedback:** add only missing buffer-local actions and compatible
   semantic-token support; preserve existing mappings and language settings.
3. **Unified debug/test controls:** extend Neotest and nvim-dap with explicit,
   discoverable mappings and output controls. Add Rust support only through a
   maintained adapter. Add CTest dynamically only in CMake test projects with
   an existing build tree.
4. **Project tasks:** use Overseer for configure/build/test CMake sequences and
   Nix flake validation. These tasks surface compiler diagnostics and avoid
   pretending builds/evaluations are unit tests.
5. **Completion polish:** retain nvim-cmp; add command-line completion and
   validate complete LSP capabilities.

## Key decisions

- C++ default: CMake preset if present, else CMake + Ninja; test through CTest
  only after the project enables tests.
- Nix default: `nix flake check --all-systems --no-build`; named `nix build`
  tasks remain project-selectable.
- Semantic tokens: enable on Neovim 0.11+ only for servers with a semantic
  token provider; preserve compatibility fallback.
- `nixd`: offer as an opt-in server selection, not an automatic replacement
  for `nil_ls`.

## Acceptance criteria

- A clean non-NixOS install provisioned by Mason has all declared tools and a
  NixOS install remains system-package-owned.
- Go code lenses refresh and run; LSP navigation/diagnostics/rename are
  discoverable and work buffer-locally.
- Go/Python/Rust/C++ flows can run and debug a nearest supported test; CTest is
  skipped cleanly if no enabled CTest build tree is available.
- CMake configure/build/test and Nix flake-check/build tasks populate output
  and diagnostics without hard-coded project paths.
- Completion works in normal buffers and command-line/path contexts.
- Existing smoke tests remain green and new workflows have headless coverage.
