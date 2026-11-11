# Local C/C++ runner and Nix validation assessment

**Date:** 2026-10-30  
**Method:** bounded-depth manifest/CI inspection under `/home/hugh` (caches,
`vendor`, generated build trees, and `.git` excluded); first-party upstream
sources linked below. This is an evidence report, not a configuration change.

## Finding

**Use CMake/CTest as the first C/C++ test integration, driven through CMake
presets or the detected build tree; keep the existing `lldb-dap` configuration
for debugging.** Add a Neotest CTest adapter only if running individual tests
in Neovim is desired. Do **not** make Meson, Make, Bazel, or a generic direct
compiler runner the default.

For Nix, expose explicit tasks for `nix flake check --all-systems --no-build`
and relevant `nix build .#…` targets. Do not represent a flake evaluation as a
unit-test adapter.

**Overall confidence: high for CMake/CTest + Ninja and Nix flake validation;
medium for a global Neotest adapter, because the active checkout has tests
disabled by default and no C++ Neotest adapter is currently installed.**

## Local evidence

| Signal | Evidence | Confidence |
|---|---|---:|
| Active C++ work | `/home/hugh/Documents/Projects/labs/shadPS4-AYOUB1080p` is a local Git checkout with uncommitted source edits and a 2026-10-06 local commit. Its root has `CMakeLists.txt`, `CMakePresets.json`, and `flake.nix`. | High |
| C++ build system | shadPS4’s presets define `x64-Clang-{Debug,Release,RelWithDebInfo}`; its Nix derivation uses `cmake` and `ninja`, exports compile commands, and selects a build type. | High |
| C++ test runner | shadPS4 has `option(ENABLE_TESTS … OFF)`, calls `enable_testing()`, and its test CMake file calls `gtest_discover_tests()`. Its checked-in CI configures `-G Ninja -DENABLE_TESTS=ON`, builds with `cmake --build build`, then runs `ctest --test-dir build --output-on-failure --progress -E 'GcnTest'`. | High |
| Another personal C++ fork | `/home/hugh/Documents/Projects/oss/vicinae` points to `github.com/HughScott2002/vicinae`, has CMake/Ninja presets, a Linux debug preset with `BUILD_TESTS=ON`, and a flake dev shell containing `catch2_3` and `clang-tools`. Its CI uses `cmake -S . -B build -G Ninja` then `cmake --build build --parallel`. | Medium-high |
| Existing Neovim direction | MASSIVIM already configures C/C++ `lldb-dap`, C/C++ tree-sitter/clangd support, and has Neotest only for Java/Go/Python. It already installs Overseer, but only documents it as Maven/Gradle task support. | High |
| Nix validation convention | `/home/hugh/Documents/Projects/nixos-config/Makefile` defines `check` as `nix flake check --all-systems --no-build` plus four `nix eval --raw …drvPath` checks, and `test`/`cache` use named `nix build .#…` installables. Local C++ flakes (shadPS4, Vicinae) provide package and dev-shell outputs. | High |
| Lower-priority alternatives | A top-level Meson project exists (`oss/foliate/meson.build`) and many Makefiles exist, but no active personal C/C++ CI/test invocation makes either the primary runner. No non-vendored Bazel manifest was found. | Medium |

## Recommended runner model

1. **Build:** project-local CMake preset when present; otherwise `cmake -S . -B build -G Ninja`, followed by `cmake --build build --parallel`. This aligns with active shadPS4 and Vicinae CI and avoids coupling Neovim to Ninja directly. CMake documents `cmake --build` as the generator-independent build command and supports preset-based configure/build selection. [CMake CLI](https://cmake.org/cmake/help/latest/manual/cmake.1.html)
2. **Test:** only after tests are configured (`ENABLE_TESTS=ON` / project equivalent), run `ctest --test-dir <build-dir> --output-on-failure`; preserve project exclusions/arguments in project-local tasks. CTest runs CMake-registered tests from `CTestTestfile.cmake`, supports `--test-dir`, name filtering, and failure output. [CTest manual](https://cmake.org/cmake/help/latest/manual/ctest.1.html)
3. **Debug:** retain MASSIVIM’s `lldb-dap` adapter. It is already registered for `c` and `cpp` and prompts for the built executable. Upstream nvim-dap supports launch, breakpoints, stepping, state inspection, and requires an independently installed per-language adapter. [MASSIVIM DAP config](../../lua/plugins/init.lua#L307-L367), [nvim-dap](https://github.com/mfussenegger/nvim-dap)
4. **Nix validation:** make project tasks explicit: `nix flake check --all-systems --no-build` for broad evaluation and `nix build .#<package/configuration>` for selected derivations. `nix flake check` evaluates a flake and builds its `checks` unless `--no-build` is supplied; `nix build` builds selected installables. [Nix flake check](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-check.html), [Nix build](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html)

## Neovim integration options

### Preferred: Neotest + `orjangj/neotest-ctest` (conditional)

This matches the active runner, not merely the test framework. The adapter
supports CTest projects using GoogleTest, Catch2, doctest, and CppUTest; it
expects CMake test enumeration such as `gtest_discover_tests()`, does not
build sources itself, and can debug an individual test with Neotest’s DAP
strategy. shadPS4 meets its CTest/GoogleTest prerequisites once configured
with `ENABLE_TESTS=ON`; Vicinae’s local flake indicates Catch2 availability.

Use it only after a build tree exists and only for projects with CTest enabled.
That limitation matters because shadPS4 disables tests by default. Neotest
itself lists both C++ CTest and GoogleTest adapters, and documents
`run.run({ strategy = "dap" })` for adapter-supported debug runs.

Sources: [Neotest supported runners and DAP strategy](https://github.com/nvim-neotest/neotest#supported-runners), [neotest-ctest](https://github.com/orjangj/neotest-ctest).

### Useful fallback: direct Overseer tasks

For configure/build/test/flake commands, a direct task is more reliable than
test discovery: it can run project-specific presets, enable test flags, carry
CI exclusions, and surface compiler diagnostics. MASSIVIM already includes
Overseer. Its upstream project supports Make and `.vscode/tasks.json`, custom
multi-stage workflows, diagnostics/quickfix integration, and `preLaunchTask`
for nvim-dap. This is the right default for CMake build and Nix validation
commands, whether or not Neotest is added.

Source: [Overseer](https://github.com/stevearc/overseer.nvim).

### Not recommended as the first addition: `neotest-gtest`

It can run/debug GoogleTest but requires manual assignment of test source to
an executable and deliberately has no build-tool integration. That is less
compatible with the local CMake/CTest CI contract than `neotest-ctest`.
Consider it only for a GTest-only repository without usable CTest registration.

Source: [neotest-gtest](https://github.com/alfaix/neotest-gtest).

## Scope boundaries

- No evidence supports making a Meson adapter, Make runner, or Bazel adapter a
  global default.
- Do not replace `lldb-dap` with CodeLLDB: the live design explicitly defers
  that choice, while nvim-dap’s C/C++ guidance supports native GDB or LLDB-DAP
  configurations. [MASSIVIM design](../superpowers/specs/2026-10-30-smooth-config-design.md#L23), [nvim-dap C/C++ guidance](https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation).
- On NixOS, preserve the project policy that runtime tools are system packages;
  only document package changes if an implementation actually adds a runtime
  dependency.
