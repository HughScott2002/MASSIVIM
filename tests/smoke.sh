#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_HOME=$(mktemp -d)
WORK_HOME=$(mktemp -d)
trap 'rm -rf "$CONFIG_HOME" "$WORK_HOME"' EXIT
ln -s "$ROOT" "$CONFIG_HOME/nvim"

run_nvim() {
  XDG_CONFIG_HOME="$CONFIG_HOME" \
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" \
    nvim --headless "$@"
}

run_assertion() {
  local assertion=$1
  local script="$WORK_HOME/assertion.lua"
  cat > "$script" <<EOF
local ok, err = xpcall(function()
  $assertion
end, debug.traceback)

if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
EOF
  run_nvim "+luafile $script" '+qa!'
}

check() {
  local name=$1
  shift
  if "$@"; then
    printf 'PASS %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name" >&2
    return 1
  fi
}

check "config loads" run_nvim '+qa!'

check "rust analyzer uses valid clippy schema" run_assertion '
  vim.cmd("Lazy! load nvim-lspconfig")
  local settings = vim.lsp.config.rust_analyzer.settings["rust-analyzer"]
  assert(type(settings.checkOnSave) == "boolean", "checkOnSave must be boolean")
  assert(settings.check.command == "clippy", "check.command must be clippy")
  assert(settings.cargo.allFeatures == true, "cargo.allFeatures is disabled")
  assert(settings.procMacro.enable == true, "proc macro expansion is disabled")
  assert(type(settings.inlayHints) == "table", "rust-analyzer inlay hints are missing")
'

mkdir -p "$WORK_HOME/rust-fixture/src"
cat > "$WORK_HOME/rust-fixture/Cargo.toml" <<'EOF'
[package]
name = "clippy_fixture"
version = "0.1.0"
edition = "2021"
EOF
cat > "$WORK_HOME/rust-fixture/src/main.rs" <<'EOF'
fn main() {
    let flag = true;
    if flag == true {
        println!("yes");
    }
}
EOF
export FIXTURE="$WORK_HOME/rust-fixture"
check "rust-analyzer publishes clippy diagnostics after save" run_assertion '
  if vim.fn.executable "rust-analyzer" == 0 or vim.fn.executable "cargo" == 0 then return end
  vim.cmd("Lazy! load nvim-lspconfig")
  vim.cmd("edit " .. vim.fn.fnameescape(assert(vim.env.FIXTURE) .. "/src/main.rs"))
  local bufnr = vim.api.nvim_get_current_buf()
  assert(vim.wait(60000, function()
    return #vim.lsp.get_clients { bufnr = bufnr } > 0
  end, 500), "rust-analyzer did not attach")

  vim.cmd("write")
  local warned = vim.wait(90000, function()
    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
      local message = (diagnostic.message or ""):lower()
      local source = (diagnostic.source or ""):lower()
      if message:find("bool", 1, true) or source:find("clippy", 1, true) then return true end
    end
    return false
  end, 500)
  assert(warned, "rust-analyzer published no clippy diagnostic after save")
'
unset FIXTURE

check "rust code action keymap is available" run_assertion '
  vim.wait(1000)
  assert(vim.fn.maparg(" ca", "n") ~= "", "code action keymap is unavailable")
'

check "clangd stays language-scoped with nvim-cmp capabilities" run_assertion '
  vim.cmd("Lazy! load nvim-lspconfig")
  local clangd = vim.lsp.config.clangd
  for _, arg in ipairs(clangd.cmd) do
    assert(not arg:match("^-std="), "clangd must not pass a global -std flag")
  end
  assert(vim.tbl_contains(clangd.root_markers, "compile_commands.json"), "clangd root markers lack compile_commands.json")
  assert(vim.tbl_contains(clangd.root_markers, ".clangd"), "clangd root markers lack .clangd")
  assert(clangd.capabilities.textDocument.completion.editsNearCursor == true, "clangd completion capability is missing")
  assert(#clangd.capabilities.offsetEncoding > 0, "clangd offset encoding is missing")
  assert(pcall(require, "cmp_nvim_lsp"), "nvim-cmp LSP provider is unavailable")
'

check "neotest keymap triggers loading" run_assertion '
  vim.wait(1000)
  assert(vim.fn.maparg(" tn", "n") ~= "", "test-nearest keymap is unavailable")
'

check "JSON and YAML schemas use SchemaStore" run_assertion '
  vim.cmd("Lazy! load nvim-lspconfig")
  assert(pcall(require, "schemastore"), "SchemaStore is unavailable")
  assert(#require("schemastore").json.schemas() > 0, "JSON SchemaStore is empty")
  assert(next(require("schemastore").yaml.schemas()) ~= nil, "YAML SchemaStore is empty")
'

check "declares Go workflow plugins and tooling" run_assertion '
  vim.wait(1000)
  vim.cmd("Lazy! load nvim-lspconfig")
  local plugins = require("lazy.core.config").plugins
  for _, name in ipairs { "nvim-lint", "nvim-dap-go", "neotest-golang" } do
    assert(plugins[name], name .. " is not declared")
  end

  local gopls = vim.lsp.config.gopls.settings.gopls
  assert(gopls.gofumpt == true, "gopls gofumpt is disabled")
  assert(gopls.staticcheck == true, "gopls staticcheck is disabled")
  assert(gopls.analyses and gopls.analyses.unusedparams == true, "gopls unusedparams analysis is disabled")

  local formatters = require("configs.conform").formatters_by_ft.go or {}
  assert(vim.tbl_contains(formatters, "goimports"), "Go formatter list lacks goimports")
  assert(vim.tbl_contains(formatters, "gofumpt"), "Go formatter list lacks gofumpt")

  vim.cmd("Lazy! load nvim-lint")
  local linters = require("lint").linters_by_ft.go or {}
  assert(vim.tbl_contains(linters, "golangcilint"), "Go linter list lacks golangcilint")

  vim.cmd("Lazy! load nvim-dap-go")
  local dap = require("dap")
  assert(dap.adapters.go, "nvim-dap-go did not register the Go adapter")
  assert(dap.configurations.go, "nvim-dap-go did not register Go configurations")
'

check "declares Python workflow plugins and tooling" run_assertion '
  vim.wait(1000)
  local plugins = require("lazy.core.config").plugins
  for _, name in ipairs { "nvim-dap-python", "neotest-python", "venv-selector.nvim" } do
    assert(plugins[name], name .. " is not declared")
  end

  local formatters = require("configs.conform").formatters_by_ft.python or {}
  assert(vim.tbl_contains(formatters, "ruff_format"), "Python formatter list lacks ruff_format")
  assert(vim.tbl_contains(formatters, "ruff_organize_imports"), "Python formatter list lacks ruff_organize_imports")

  vim.cmd("Lazy! load nvim-dap-python")
  local dap = require("dap")
  assert(dap.adapters.python, "nvim-dap-python did not register the Python adapter")
  assert(dap.configurations.python, "nvim-dap-python did not register Python configurations")

  vim.cmd("Lazy! load neotest")
  assert(pcall(require, "neotest-golang"), "neotest-golang is unavailable")
  assert(pcall(require, "neotest-python"), "neotest-python is unavailable")
  assert(vim.fn.maparg(" cv", "n") ~= "", "Python virtualenv keymap is unavailable")
'

check "declares Nix formatter and linter" run_assertion '
  vim.wait(1000)
  vim.cmd("Lazy! load nvim-lint")
  local formatters = require("configs.conform").formatters_by_ft.nix or {}
  assert(vim.tbl_contains(formatters, "nixfmt"), "Nix formatter list lacks nixfmt")
  local linters = require("lint").linters_by_ft.nix or {}
  assert(vim.tbl_contains(linters, "statix"), "Nix linter list lacks statix")
'

check "Go, Python, and Nix writes degrade without missing tools" run_assertion '
  local fixtures = {
    { name = "main.go", ft = "go", lines = { "package main", "func main() {}" } },
    { name = "main.py", ft = "python", lines = { "def main():", "    return 1" } },
    { name = "default.nix", ft = "nix", lines = { "{ pkgs }: pkgs.hello" } },
  }

  for _, fixture in ipairs(fixtures) do
    local path = "'"$WORK_HOME"'/" .. fixture.name
    vim.fn.writefile(fixture.lines, path)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.bo.filetype = fixture.ft
    vim.cmd("write")
  end
'

printf 'line with markdown hard break  \n' > "$WORK_HOME/hard-break.md"
check "safe writes preserve markdown hard breaks" run_assertion '
  vim.cmd("edit " .. vim.fn.fnameescape("'"$WORK_HOME"'/hard-break.md"))
  vim.cmd("write")
  local file = assert(io.open("'"$WORK_HOME"'/hard-break.md", "r"))
  local contents = file:read("*a")
  file:close()
  assert(contents:match("  \n$") ~= nil, "Markdown hard break was removed")
'

printf 'plain text   \n' > "$WORK_HOME/nonmodifiable.txt"
check "safe writes do not error for nonmodifiable buffers" run_assertion '
  vim.cmd("edit " .. vim.fn.fnameescape("'"$WORK_HOME"'/nonmodifiable.txt"))
  vim.bo.modifiable = false
  vim.cmd("write")
'
