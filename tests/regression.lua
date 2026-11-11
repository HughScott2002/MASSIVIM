local function run()
  vim.cmd "Lazy! load nvim-treesitter"
  require("configs.treesitter").check_versions()
  local base = "tests/fixtures/coverage/"
  local function parse(name, lang)
    local source = table.concat(vim.fn.readfile(base .. name), "\n")
    local parser = vim.treesitter.get_string_parser(source, lang)
    local tree = assert(parser:parse()[1])
    assert(not tree:root():has_error(), name .. " has a top-level syntax error")
    return parser
  end
  parse("unsafe.rs", "rust")
  parse("identity.sh", "bash")
  parse("valid.jsonc", "json5")
  parse("feature.cu", "cuda")
  parse("feature.astro", "astro")
  parse("feature.jinja", "jinja")
  parse("feature.qml", "qmljs")
  parse("feature.frag", "glsl")
  local workflow = parse("workflow.yml", "yaml")
  workflow:parse(true)
  local seen = {}
  workflow:for_each_tree(function(tree, language_tree)
    seen[language_tree:lang()] = true
    assert(not tree:root():has_error(), "valid workflow shell injection has an error")
  end)
  assert(seen.bash and seen.powershell, "workflow shells were not resolved independently")

  vim.cmd("edit " .. vim.fn.fnameescape(base .. "feature.ndjson"))
  assert(vim.bo.filetype == "jsonl")
  local ns = assert(vim.api.nvim_get_namespaces()["massivim.jsonl"])
  local errors = vim.diagnostic.get(0, { namespace = ns })
  assert(#errors == 1 and errors[1].lnum == 2, "JSONL must isolate the truncated final record")
  assert(errors[1].message == "Invalid JSON record on this line", "JSONL diagnostics must not quote data")
  vim.api.nvim_buf_set_lines(0, 2, 3, false, { '{"recovered":true}' })
  vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })
  assert(#vim.diagnostic.get(0, { namespace = ns }) == 0, "JSONL did not recover after repair")
  vim.cmd "bwipeout!"

  for _, case in ipairs {
    { "feature.metal", "metal", "metal" },
    { "feature.cl", "opencl", "opencl" },
    { "feature.service", "systemd", nil },
    { "feature.xml.in", "xml", nil },
  } do
    vim.cmd("edit " .. vim.fn.fnameescape(base .. case[1]))
    assert(vim.bo.filetype == case[2], case[1] .. " incorrect filetype " .. vim.bo.filetype)
    if case[3] then
      assert(vim.bo.syntax == case[3], case[1] .. " has no declared syntax fallback")
      assert(vim.b.current_syntax == case[3], case[1] .. " syntax fallback did not load")
    end
    vim.cmd "bwipeout!"
  end
  for _, case in ipairs {
    { "translation.ts", "xml" },
    { "module.ts", "typescript" },
    { "matrix.m", "matlab" },
    { "feature.m", "objc" },
    { "feature.mm", "objcpp" },
  } do
    vim.cmd("edit " .. vim.fn.fnameescape(base .. case[1]))
    assert(vim.bo.filetype == case[2], "ambiguous suffix: " .. case[1] .. " detected " .. vim.bo.filetype)
    vim.cmd "bwipeout!"
  end
  vim.cmd "Lazy! load nvim-lspconfig"
  local astro, params = vim.deepcopy(vim.lsp.config.astro), {}
  astro.root_dir = vim.fn.getcwd()
  astro.before_init(params, astro)
  assert(params.initializationOptions.typescript.tsdk, "Astro SDK not sent in actual initialize params")
  assert(vim.fn.filereadable(params.initializationOptions.typescript.tsdk .. "/tsserverlibrary.js") == 1)
  local kotlin, kotlin_params = vim.deepcopy(vim.lsp.config.kotlin_language_server), {}
  kotlin.before_init(kotlin_params, kotlin)
  assert(
    type(kotlin_params.initializationOptions.storagePath) == "string",
    "Kotlin initialize options must be an object"
  )
  local clangd = vim.lsp.config.clangd
  assert(vim.tbl_contains(clangd.cmd, "--function-arg-placeholders=true"))
  assert(
    clangd.capabilities.general and clangd.capabilities.general.positionEncodings,
    "standard position encoding negotiation is missing"
  )
  assert(not vim.tbl_contains(vim.lsp.config.sourcekit.filetypes, "cpp"), "SourceKit competes with clangd")
  assert(vim.g.vscode_snippets_path and #vim.g.vscode_snippets_path == 0)
  assert(vim.g.lua_snippets_path and #vim.g.lua_snippets_path == 0)
  vim.cmd "Lazy! load LuaSnip"
  local ls = require "luasnip"
  vim.cmd "enew"
  vim.bo.filetype = "lua"
  assert(
    vim.wait(3000, function()
      return #ls.get_snippets "lua" > 0
    end, 50),
    "friendly snippets did not load"
  )
  ls.snip_expand(ls.get_snippets("lua")[1])
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") ~= "", "bundled snippet did not expand")
  vim.cmd "bwipeout!"
  print "PASS parser, injection, mapping, JSONL recovery and configuration regressions"
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd "cquit 1"
end
