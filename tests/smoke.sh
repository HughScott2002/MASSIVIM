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

check "rust analyzer uses current check schema" run_assertion '
  vim.cmd("Lazy! load nvim-lspconfig")
  local settings = vim.lsp.config.rust_analyzer.settings["rust-analyzer"]
  assert(type(settings.checkOnSave) == "boolean", "checkOnSave must be boolean")
  assert(settings.check.command == "clippy", "check.command must be clippy")
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
