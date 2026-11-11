local M = {}

function M.check_versions()
  assert(vim.fn.has "nvim-0.12" == 1, "MASSIVIM requires Neovim >= 0.12; upgrade Neovim before installing parsers")
  local result = vim.system({ "tree-sitter", "--version" }, { text = true }):wait(10000)
  local version = (result.stdout or ""):match "(%d+%.%d+%.%d+)"
  assert(
    result.code == 0 and version and vim.version.ge(version, "0.26.1"),
    "MASSIVIM requires tree-sitter CLI >= 0.26.1; install unstable.tree-sitter on NixOS or upgrade tree-sitter-cli"
  )
end

function M.install(languages, update)
  M.check_versions()
  local root = vim.fn.stdpath "config"
  local prepared = vim
    .system({ "python3", root .. "/scripts/prepare-grammars.py", vim.fn.stdpath "cache" }, { text = true })
    :wait(300000)
  assert(prepared.code == 0, "Grammar patch preparation failed: " .. (prepared.stderr or ""))
  local overrides = {}
  for line in (prepared.stdout or ""):gmatch "[^\n]+" do
    local lang, path, revision = line:match "^([^\t]+)\t([^\t]+)\t(.+)$"
    if lang then
      overrides[lang] = { path = path, revision = revision, generate = true }
    end
  end
  local function apply_overrides()
    local registry = require "nvim-treesitter.parsers"
    for lang, info in pairs(overrides) do
      registry[lang].install_info = info
    end
  end
  apply_overrides()
  vim.fn.writefile({ vim.json.encode(overrides) }, vim.fn.stdpath "cache" .. "/massivim-grammar-overrides.json")
  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = apply_overrides,
    group = vim.api.nvim_create_augroup("massivim.grammar_patches", { clear = true }),
  })
  local ts = require "nvim-treesitter"
  local success = ts.install(languages):wait(900000)
  if update ~= false then
    success = ts.update(languages):wait(900000) and success
  end
  assert(
    success,
    "Tree-sitter installation failed; inspect :messages for the failed language and rerun :MassivimParsers after fixing the tool/network error"
  )
  local installed = ts.get_installed "parsers"
  for _, lang in ipairs(languages) do
    assert(vim.tbl_contains(installed, lang), "Tree-sitter did not install " .. lang)
  end
end

function M.setup(opts)
  assert(vim.fn.has "nvim-0.12" == 1, "MASSIVIM requires Neovim >= 0.12")
  require "configs.shell_injections"
  local query = vim.fn.stdpath "config" .. "/after/queries/yaml/injections.scm"
  vim.treesitter.query.set("yaml", "injections", table.concat(vim.fn.readfile(query), "\n"))
  require("nvim-treesitter").setup(opts)
  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    group = vim.api.nvim_create_augroup("massivim.grammar_patches", { clear = true }),
    callback = function()
      local file = vim.fn.stdpath "cache" .. "/massivim-grammar-overrides.json"
      assert(vim.fn.filereadable(file) == 1, "Run :MassivimParsers to prepare pinned grammar fixes before :TSUpdate")
      local overrides = vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
      for lang, info in pairs(overrides) do
        assert(
          vim.fn.filereadable(info.path .. "/.massivim-ready") == 1,
          "Missing patched sources; run :MassivimParsers"
        )
        require("nvim-treesitter.parsers")[lang].install_info = info
      end
    end,
  })
  vim.api.nvim_create_user_command("MassivimParsers", function()
    M.install(opts.ensure_installed)
  end, {})
  -- Startup is deliberately offline-safe. Installation is explicit and bounded.
  local installed = require("nvim-treesitter").get_installed "parsers"
  local missing = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(installed, lang)
  end, opts.ensure_installed)
  if #missing > 0 and not vim.env.MASSIVIM_AUDIT then
    vim.schedule(function()
      vim.notify(
        "Missing parsers: " .. table.concat(missing, ", ") .. ". Run :MassivimParsers (CLI >= 0.26.1 required).",
        vim.log.levels.WARN
      )
    end)
  end
  vim.treesitter.language.register("json5", "jsonc")
  vim.treesitter.language.register("linkerscript", "ld")
  vim.treesitter.language.register("hlsl", "cg")
  vim.treesitter.language.register("hcl", { "terraform", "terraform-vars" })
  vim.treesitter.language.register("htmldjango", "htmldjango")
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("massivim.treesitter", { clear = true }),
    callback = function(ev)
      if
        vim.bo[ev.buf].filetype == "jsonl"
        or vim.bo[ev.buf].filetype == "metal"
        or vim.bo[ev.buf].filetype == "opencl"
      then
        return
      end
      local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
      if not lang then
        return
      end
      local available, loaded = pcall(vim.treesitter.language.add, lang)
      if not available or not loaded then
        return
      end
      local ok, err = pcall(vim.treesitter.start, ev.buf, lang)
      if not ok then
        vim.notify("Tree-sitter " .. lang .. ": " .. tostring(err), vim.log.levels.ERROR)
        return
      end
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end
return M
