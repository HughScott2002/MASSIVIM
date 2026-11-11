#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_HOME=$(mktemp -d)
WORK_HOME=$(mktemp -d)
DATA_HOME="$WORK_HOME/xdg-data"
STATE_HOME="$WORK_HOME/xdg-state"
CACHE_HOME="$WORK_HOME/xdg-cache"
trap 'rm -rf "$CONFIG_HOME" "$WORK_HOME"' EXIT
cp -a "$ROOT" "$CONFIG_HOME/nvim"

mkdir -p "$DATA_HOME/nvim" "$STATE_HOME" "$CACHE_HOME"
cp -a "$HOME/.local/share/nvim/lazy" "$DATA_HOME/nvim/lazy"
cp -a "$HOME/.local/share/nvim/base46" "$DATA_HOME/nvim/base46"
cp -a "$HOME/.local/share/nvim/lazy-rocks" "$DATA_HOME/nvim/lazy-rocks"
cp -a "$HOME/.local/share/nvim/site" "$DATA_HOME/nvim/site"

# A disposable Mason-compatible debugpy adapter lets the DAP test prove that
# nvim-dap-python uses Mason when it is available without changing the user's
# Mason installation.
mkdir -p "$DATA_HOME/nvim/mason/bin"
touch "$DATA_HOME/nvim/mason/bin/debugpy-adapter"
chmod +x "$DATA_HOME/nvim/mason/bin/debugpy-adapter"

run_nvim() {
  XDG_CONFIG_HOME="$CONFIG_HOME" \
    XDG_DATA_HOME="$DATA_HOME" \
    XDG_STATE_HOME="$STATE_HOME" \
    XDG_CACHE_HOME="$CACHE_HOME" \
    MASSIVIM_AUDIT=1 nvim --headless --cmd "set nomodeline" "$@"
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

check "smoke suite uses temporary XDG directories" run_assertion '
  assert(vim.fn.stdpath("data") == "'"$DATA_HOME"'/nvim", "smoke suite is using shared Neovim data")
  assert(vim.fn.stdpath("state") == "'"$STATE_HOME"'/nvim", "smoke suite is using shared Neovim state")
  assert(vim.fn.stdpath("cache") == "'"$CACHE_HOME"'/nvim", "smoke suite is using shared Neovim cache")
'

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
  local fixture = assert(vim.env.FIXTURE)
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))
  vim.cmd("Lazy! load nvim-lspconfig")
  vim.cmd("edit " .. vim.fn.fnameescape(fixture .. "/src/main.rs"))
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
  assert(vim.tbl_contains(clangd.cmd, "--function-arg-placeholders=true"), "clangd placeholder flag needs a boolean")
  assert(pcall(require, "cmp_nvim_lsp"), "nvim-cmp LSP provider is unavailable")
'

check "neotest keymap triggers loading" run_assertion '
  assert(not package.loaded.neotest, "neotest loaded before its key was used")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(" tn", true, false, true), "mx", false)
  assert(vim.wait(5000, function() return package.loaded.neotest ~= nil end, 50), "test-nearest key did not load neotest")
'

check "JSON and YAML schemas use SchemaStore" run_assertion '
  vim.cmd("Lazy! load nvim-lspconfig")
  assert(pcall(require, "schemastore"), "SchemaStore is unavailable")
  assert(#require("schemastore").json.schemas() > 0, "JSON SchemaStore is empty")
  assert(next(require("schemastore").yaml.schemas()) ~= nil, "YAML SchemaStore is empty")
'

check "every completion source has a provider" run_assertion '
  vim.wait(1000)
  vim.cmd("Lazy! load nvim-cmp")
  local providers = {
    nvim_lsp = "cmp_nvim_lsp",
    luasnip = "cmp_luasnip",
    buffer = "cmp_buffer",
    nvim_lua = "cmp_nvim_lua",
    async_path = "cmp_async_path",
    path = "cmp_path",
  }
  local sources = require("cmp").get_config().sources
  assert(#sources > 0, "nvim-cmp has no configured sources")
  for _, source in ipairs(sources) do
    local provider = providers[source.name]
    assert(provider, "no provider is mapped for completion source " .. source.name)
    assert(pcall(require, provider), "provider " .. provider .. " is unavailable for " .. source.name)
  end
'

check "markdown and color plugins are maintained replacements" run_assertion '
  vim.wait(1000)
  local plugins = require("lazy.core.config").plugins
  assert(not plugins["import-cost.nvim"], "archived import-cost is still declared")
  assert(plugins["nvim-colorizer.lua"], "colorizer is not declared")
  assert(plugins["nvim-colorizer.lua"].url:find("catgoose", 1, true), "colorizer is not the maintained catgoose fork")
  assert(plugins["render-markdown.nvim"], "render-markdown is not declared")
  assert(plugins["markdown-preview.nvim"], "markdown-preview was removed")

  local css = "'"$WORK_HOME"'/colors.css"
  vim.fn.writefile({ ".a { color: #ff0000; }" }, css)
  vim.cmd("edit " .. vim.fn.fnameescape(css))
  vim.bo.filetype = "css"
  vim.wait(500)
  assert(pcall(require, "colorizer"), "opening CSS did not load catgoose colorizer")
  require("colorizer").attach_to_buffer(0)
  vim.wait(500)
  local namespace = vim.api.nvim_get_namespaces().colorizer
  assert(namespace, "colorizer namespace is missing")
  assert(#vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, {}) > 0, "colorizer did not highlight a hex color")

  local markdown = "'"$WORK_HOME"'/render.md"
  vim.fn.writefile({ "# Title", "", "- item", "", "```lua", "print(1)", "```" }, markdown)
  vim.cmd("edit " .. vim.fn.fnameescape(markdown))
  vim.bo.filetype = "markdown"
  vim.wait(1500)
  assert(pcall(require, "render-markdown"), "opening Markdown did not load render-markdown")
  local rendered = false
  for _, id in pairs(vim.api.nvim_get_namespaces()) do
    if #vim.api.nvim_buf_get_extmarks(0, id, 0, -1, {}) > 0 then rendered = true end
  end
  assert(rendered, "render-markdown produced no in-buffer rendering")

  assert(vim.fn.maparg(" mp", "n") ~= "", "markdown preview mapping is unavailable")
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

  local go_file = "'"$WORK_HOME"'/workflow.go"
  vim.fn.writefile({ "package main" }, go_file)
  vim.cmd("edit " .. vim.fn.fnameescape(go_file))
  vim.wait(500)
  assert(package.loaded["dap-go"], "opening Go did not load nvim-dap-go")
  assert(package.loaded.lint, "opening Go did not load nvim-lint")
  local linters = require("lint").linters_by_ft.go or {}
  assert(vim.tbl_contains(linters, "golangcilint"), "Go linter list lacks golangcilint")

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

  local python_file = "'"$WORK_HOME"'/workflow.py"
  vim.fn.writefile({ "print(1)" }, python_file)
  vim.cmd("edit " .. vim.fn.fnameescape(python_file))
  vim.wait(500)
  assert(package.loaded["dap-python"], "opening Python did not load nvim-dap-python")
  local dap = require("dap")
  assert(dap.adapters.python, "nvim-dap-python did not register the Python adapter")
  assert(dap.configurations.python, "nvim-dap-python did not register Python configurations")

  vim.cmd("Lazy! load neotest")
  assert(pcall(require, "neotest-golang"), "neotest-golang is unavailable")
  assert(pcall(require, "neotest-python"), "neotest-python is unavailable")
  assert(vim.fn.maparg(" cv", "n") ~= "", "Python virtualenv keymap is unavailable")
'

check "Python DAP prefers Mason debugpy when present" run_assertion '
  vim.cmd("Lazy! load nvim-dap-python")
  local adapter
  require("dap").adapters.python(function(value) adapter = value end, { request = "launch" })
  assert(adapter and adapter.command == "'"$DATA_HOME"'/nvim/mason/bin/debugpy-adapter", "Python DAP did not select Mason debugpy-adapter")
'

check "declares Nix formatter and linter" run_assertion '
  vim.wait(1000)
  local nix_file = "'"$WORK_HOME"'/workflow.nix"
  vim.fn.writefile({ "{ }: 1" }, nix_file)
  vim.cmd("edit " .. vim.fn.fnameescape(nix_file))
  vim.wait(500)
  assert(package.loaded.lint, "opening Nix did not load nvim-lint")
  local formatters = require("configs.conform").formatters_by_ft.nix or {}
  assert(vim.tbl_contains(formatters, "nixfmt"), "Nix formatter list lacks nixfmt")
  local linters = require("lint").linters_by_ft.nix or {}
  assert(vim.tbl_contains(linters, "statix"), "Nix linter list lacks statix")
'

check "Go, Python, and Nix writes degrade without missing tools" run_assertion '
  vim.cmd("Lazy! load nvim-lint")
  local conform = require("conform")
  local lint = require("lint")
  for _, name in ipairs { "goimports", "gofumpt", "ruff_organize_imports", "ruff_format", "nixfmt" } do
    conform.formatters[name] = { command = "massivim-smoke-missing-" .. name }
  end
  for _, name in ipairs { "golangcilint", "ruff", "statix" } do
    lint.linters[name].cmd = "massivim-smoke-missing-" .. name
  end
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
