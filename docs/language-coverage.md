# Language coverage

MASSIVIM requires Neovim **0.12+**. Parser maintenance requires the native
Tree-sitter CLI **0.26.1+**, Python 3, Git, Node, curl, tar and a C compiler.
The plugin revision is recorded in `lazy-lock.json`; grammar versions come from
that revision's registry, with the two bounded patches documented below.

Coverage has separate meanings: detection, native syntax, Tree-sitter parsing,
queries/highlighting, and semantic tooling. A working highlighter does not prove
SDK-backed analysis, and a successful LSP initialize does not prove navigation.
`tests/coverage.lua` reports top-level errors, injected snippet errors and runtime
exceptions separately. Machine-specific inventories and findings are kept outside
this repository. Submodule coverage uses representative files, not a claim that
every vendor fixture is valid source.

## Ownership and installation

On NixOS, install the package block in README and rebuild the system. Mason stays
disabled. The tested unstable input was `151fa4e8ddfd` (26.11pre1086391), including
Tree-sitter 0.26.11, vscode-langservers-extracted 1.126.04524, Flutter 3.41.9 with Dart 3.11.5,
Astro language server 2.16.10, Swift/SourceKit 6.2.4, WGSL analyzer 2026-04-26,
PSES 4.7.0 with PowerShell 7.6.6, Kotlin language server 1.3.13, terraform-ls
0.39.0, glsl_analyzer 1.7.1, Ruby LSP 0.26.3, Taplo 0.10.0 and MesonLSP 5.0.4.
The stable TypeScript SDK is 5.9.3. Versions are observations of the tested input;
future channel updates need the same protocol and fixture checks.

On other systems, `setup.sh` checks Neovim and installs the native CLI through
Homebrew or a pinned Cargo build into `~/.local`. Mason owns its declared tools.
Install Dart/Flutter, Swift/SourceKit, Qt/QML, Java, Ruby/Bundler, .NET and Rust
runtimes through their platform/toolchain owners. PSES also needs PowerShell.
The Mason package list is configuration, **not an end-to-end WSL installation
result**. WSL and macOS checks need actual suitable hosts.

`MassivimParsers` waits for installation and update, checks the boolean result,
and verifies every declared parser exists. Failures propagate through setup's
headless command as a nonzero exit. Startup never downloads parsers. It uses the
installed set offline and gives one actionable missing-parser notice. Direct
`TSUpdate` retains prepared patch overrides; if their cache has gone, use
`MassivimParsers` to prepare it again. There are no repeated offline install
attempts or a Neovim 0.11 compatibility polyfill.

## Principal language strategies

The parser column names the registry grammar, which can differ from filetype.
The server configuration comes from the locked nvim-lspconfig definitions.

| Filetype / language | Tree-sitter strategy | Semantic tool / command | Root and prerequisites |
|---|---|---|---|
| HTML, CSS, JSON/JSONC | html, css, json / json5 | html, cssls, jsonls: `vscode-*-language-server --stdio` | System package or Mason; JSONC validation remains with jsonls |
| TypeScript/TSX, JavaScript/JSX | typescript, tsx, javascript | ts_ls: `typescript-language-server --stdio`; denols: `deno lsp` | Node project markers; Deno roots exclude ts_ls |
| Astro | astro, embedded TypeScript | astro: `astro-ls --stdio` | package.json/tsconfig/.git; local SDK preferred, global SDK fallback, TS <=6 with tsserverlibrary.js |
| Dart/Flutter | dart | dartls: `dart language-server --protocol=lsp` | Nearest pubspec.yaml; Flutter SDK/dependencies belong to the project |
| Swift | swift | sourcekit: `sourcekit-lsp` | Package.swift, buildServer.json, Xcode workspace/project, .git; matching Swift SDK |
| PowerShell | powershell | powershell_es: PSES via `pwsh` or Nix wrapper | .git / PSScriptAnalyzerSettings.psd1; log/session paths in user cache |
| WGSL | wgsl | wgsl_analyzer: `wgsl-analyzer` | .git; shader language/server version may limit newer constructs |
| QML | qmljs | qmlls: `qmlls` | Qt SDK and project-owned QML build/import context; .git root |
| Rust | rust with pinned safe-extern patch | rust_analyzer: `rust-analyzer` | Cargo.toml; coherent Cargo/rustc/analyzer/rust-src and Clippy |
| C / C++ | c / cpp | clangd: `clangd` | Project compile_commands.json / compile_flags.txt; no global -std or invented include paths |
| CUDA | cuda | clangd with CUDA compile context | Syntax fixture includes kernel launch; semantic support needs a real CUDA SDK/build database |
| Objective-C | objc | clangd, where an SDK/build context exists | Linux syntax tests do not validate macOS Cocoa semantics |
| Objective-C++ | Native objcpp syntax; no compatible registry grammar claimed | clangd with Apple SDK on a Mac | Mixed ObjC/C++ fixture intentionally remains a Tree-sitter limitation |
| Metal / OpenCL | Owned Metal/OpenCL native syntax fallback | Project SDK tools | No full Tree-sitter or SDK semantic claim; actual shader constructs retained |
| Ruby | ruby | ruby_lsp: `ruby-lsp` | Gemfile/.git; packaged gems used directly on NixOS, no implicit bundle downloads; use project dev shell for dependencies |
| HCL / Terraform | hcl; terraform/terraform-vars explicitly map to hcl | terraformls: `terraform-ls serve` | .terraform/.git; Terraform semantics do not validate every arbitrary HCL dialect |
| Kotlin | kotlin | kotlin_language_server: `kotlin-language-server` | Gradle/Maven markers, Java; explicit object initialization and cache directory |
| C# | c_sharp | existing roslyn_ls | .NET SDK and project/solution context; no competing C# server |
| GLSL / HLSL | glsl / hlsl | glsl_analyzer: `glsl_analyzer` for GLSL | .git; HLSL semantic compiler/SDK remains project-owned |
| TOML | toml | taplo: `taplo lsp stdio` | taplo.toml/.taplo.toml/.git; external schema-catalog failures are reported separately |
| Meson | meson | mesonlsp: `mesonlsp --lsp` | meson.build; project dependencies are not auto-installed by the editor |
| Jinja / Django templates | jinja / htmldjango | HTML semantics only for actual HTML buffers | Template parsing is tested separately; no claim of full Django/Jinja evaluation or embedded HTML navigation |
| Starlark / Bazel | starlark for bzl/BUILD.bazel | Project tools | .bazelrc is configuration syntax, not Starlark source |
| RST, assembly, Fish, Nu | rst, asm/nasm, fish, nu | Native/project tools as applicable | Assembly dialects vary; Go assembler and vendor macros can exceed the selected grammar |
| Scheme/Lisp, Tcl, Luau | scheme/commonlisp, tcl, luau | Native/project tools as applicable | Macro/token-stream grammar errors are not proof of invalid source |
| Just, jq, Mermaid | just, jq, mermaid | Native/project tools as applicable | Mermaid `graph` fixture exposes a registry grammar limitation; not marked full support |
| Fluent, Prolog, m4, AsciiDoc, lex/yacc, installer formats | Native syntax where available, including owned basic Fluent syntax | Native/project tools | No compatible selected-registry parser/server claim; preserve explicit limitations |

Additional observed registry grammars include Groovy, awk, Perl, Pascal, GN,
LaTeX/BibTeX, DOT, properties, Android Blueprint, TLA+, Xresources, IDL,
readline, textproto and Python MANIFEST.in. Metadata parsers include desktop,
EditorConfig, gitattributes, git_config, INI, requirements and PEM. Parsing
certificate data is optional; reports never quote key/certificate contents.

New formatter entries are **explicit only**: Dart, Swift, Ruby, Terraform/HCL,
TOML, Kotlin, C#, Astro and Objective-C/C++. Missing optional formatter executables
are reported by Conform and need the platform's maintained tool (`dart format`,
`swift-format`, RuboCop, terraform, Taplo, ktlint, CSharpier, Prettier or
clang-format). They do not expand format-on-save. Markdown hard breaks remain
protected. Existing save-time behavior for other filetypes is preserved.

## Detection and data handling

- `.ts` remains TypeScript unless XML/Qt TS document markers establish a
  translation file. `.m` retains Neovim's Objective-C/MATLAB content detection;
  both are regression tested. `.mm` stays Objective-C++.
- `.inc` keeps its existing fallback, with scoped C/C++ include-fragment handling
  for observed Abseil, Zydis and utf8_range paths and PHP content markers.
  A Pascal suffix guess must not turn a generated C include into Pascal source.
- `.in` templates inherit an established inner filename's filetype. Template
  placeholders and unexpanded build fragments can remain outside a source
  grammar's accepted language. `Makefile.*` is Make, not a `.mac` assembler guess.
- Kubernetes OWNERS/import-restrictions/kuberc mappings are scoped to that
  repository; unrelated OWNERS documents are not globally renamed YAML.
- `.ndjson` and `.jsonl` use `jsonl`, JSON syntax highlighting and independent
  JSON decoding per nonblank line. Multiple records and escaped strings work;
  a truncated final record produces one line-specific diagnostic, and earlier
  records remain usable. Correcting it clears that diagnostic. Diagnostics
  report neither the record contents nor decoder text. Blank lines are ignored
  deliberately; no JSON LSP or single-document parser is attached as JSONL proof.
- systemd units use native INI syntax. Ordinary prose, legal metadata, version
  markers, keys/certificates, meshes, empty sentinels and serialized fuzz corpora
  do not need source parsers. Unknown source formats remain explicit gaps.

## Grammar corrections and limits

The two grammar patches live in `patches/` and are applied by
`scripts/prepare-grammars.py` to pinned upstream sources in user cache:

- Rust `77a3747266f4d621d0757825e6b11edcbf991ca5`: add the `safe` function
  modifier used in `unsafe extern` blocks. Native rustc accepts the fixture.
- Bash `a06c2e4415e9bc0346c6b86d401879ffb44058f7`: preserve a lone dash as the
  right operand of a bracket comparison, rather than consuming `]` as a unary
  operand. `bash -n` accepts the fixture.

The preparer regenerates grammar.json/parser.c from grammar.js before the
supported installer compiles it. Patch hashes are part of cache identities.
Downloaded plugin files and valid repository sources are not patched.

JSON5 is used for JSONC **highlighting**, not as a stricter JSONC validator.
Protocol tests separately accept JSONC comments/trailing commas and reject
JSON5-only bare keys/single quotes through jsonls.

The YAML override is owned under `after/queries/yaml/`. It retains non-Actions
injections and resolves run-step shells from explicit shell, job defaults,
workflow defaults and known runner defaults. Bash and PowerShell are tested
independently. Unknown/dynamic shell choices and `${{ ... }}` expressions are
left as YAML instead of guessing arbitrary embedded shell syntax. Successful
YAML parsing alone is never reported as shell validation.

On this NixOS host SourceKit 6.2.4's Foundation logger traps in the local time-zone
conversion. A minimal stdio probe reproduces SIGILL; the same probe passes with
`TZ=UTC`. Only SourceKit receives that environment setting. Linux still cannot
prove Apple SDK-backed bridge analysis. Mac-only plist `plutil` and actual WSL
setup are unverified without those platforms.

## Verification

Run `bash tests/smoke.sh`, `python3 tests/lsp-probe.py` and the isolated regression
command in README. `tests/isolated.sh` copies mutable state and disables
modelines, swap/undo files and auto-installation. A cold run omits parser data;
existing-parser startup is checked offline separately. Coverage manifests contain
only repo/path/scope entries and reports contain paths/counts, not source text.
The scanner checkpoints every 500 files and can resume an identical manifest
with `MASSIVIM_RESUME=1`. Runtime/query failures, invalid fixtures and genuine
unsupported constructs must remain distinct in the remediation ledger.

The tested Flutter 3.47 SDK would change six locked dependencies in the observed mobile app. Selecting the available `flutterPackages.v3_41` line lets `flutter pub get --enforce-lockfile` succeed with the existing lockfile unchanged. No dependency versions were rewritten.

## Observed semantic feature limits

Disposable projects returned nonempty hover, definition and completion responses
for Dart, Swift, PowerShell and Astro. WGSL returned definition/completion but
no hover in the tested fixture. Ruby returned RBS definition locations but no
nonempty hover/completion in its fixture; its shutdown also emitted an upstream
ClosedQueueError. Those features remain partial, not verified as fixed.
Standalone Kotlin samples without a supported build root remain unverified.
These limits do not invalidate successful parser/highlighting checks.

Some detected JSON files are templates or permissive fixture inputs. Vicinae's
extension package template uses percent placeholders and gets native
json_template syntax. Hugo Book's JSON manifest is a Go template and gets the
gotmpl grammar. The two scoped Kubernetes OpenAPI fixtures are parsed by a YAML
consumer (gnostic) and contain trailing commas; they get JSONC handling. Their
bytes are preserved. Malformed source outside these demonstrated cases is
reported rather than rewritten to satisfy a parser.

The complete appendix also includes scoped Rofi/Caddy/linker-script support,
Citation/Flatpak/Xcode/MSBuild metadata, shader includes, and header/protobuf
variants. `.bf` is resolved by project context (Brainfuck versus Beef), never a
global alias. ImHex, Tamarin, Figura, Sigil, Cryptol, CLIF, module maps, and
preprocessor templates retain named, basic lexical fallbacks; these are not
reported as full Tree-sitter or semantic implementations. Word lists, compressed
PDF maps, ciphertext, ABI dumps, expected-output snapshots and fuzz-input corpora
receive explicit data dispositions in the ledger.
