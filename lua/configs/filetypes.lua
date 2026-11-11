-- Keep ambiguous suffixes in Neovim's content-aware detector. Templates inherit
-- their inner filename only when that filename has an established filetype.
local function unit_type(_, buf)
  local headers = {
    Unit = true,
    Service = true,
    Timer = true,
    Socket = true,
    Path = true,
    Mount = true,
    Automount = true,
    Install = true,
  }
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local section = line:match "^%s*%[([^%]]+)%]%s*$"
    if headers[section] then
      return "systemd"
    end
    if section == "D-BUS Service" then
      return "dosini"
    end
  end
end
vim.filetype.add {
  extension = {
    flatpakrepo = "dosini",
    flatpakref = "dosini",
    mdc = "markdown",
    qss = "css",
    cff = "yaml",
    podspec = "ruby",
    targets = "xml",
    groupproj = "xml",
    hpp11 = "cpp",
    hlsli = "hlsl",
    protodevel = "proto",
    xcconfig = "xcconfig",
    modulemap = "modulemap",
    hexpat = "hexpat",
    spthy = "spthy",
    clif = "clif",
    cry = "cryptol",
    bazelrc = "bazelrc",
    lds = "ld",
    cmakein = "pkgconfig",
    sigil = "sigil",

    pbxproj = "pbxproj",
    bnf = "bnf",
    pest = "pest",
    xhtml = "xml",
    inc = function(path, buf)
      if path:find("/abseil-cpp/", 1, true) then
        return "cpp"
      end
      if path:find("/zydis/", 1, true) or path:find("/utf8_range/", 1, true) then
        return "c"
      end
      local head =
        table.concat(vim.api.nvim_buf_get_lines(buf, 0, math.min(40, vim.api.nvim_buf_line_count(buf)), false), "\n")
      if head:find("<?php", 1, true) then
        return "php"
      end
      if head:match "^%s*#%s*include" or head:find("__cplusplus", 1, true) then
        return "cpp"
      end
      return "pascal"
    end,
    ts = function(_, buf)
      local head =
        table.concat(vim.api.nvim_buf_get_lines(buf, 0, math.min(25, vim.api.nvim_buf_line_count(buf)), false), "\n")
      if head:match "<TS[%s>]" and (head:match "<%?xml" or head:match "<!DOCTYPE%s+TS") then
        return "xml"
      end
      return "typescript"
    end,
    ndjson = "jsonl",
    jsonl = "jsonl",
    metal = "metal",
    cl = function(path, buf)
      local lines =
        table.concat(vim.api.nvim_buf_get_lines(buf, 0, math.min(100, vim.api.nvim_buf_line_count(buf)), false), "\n")
      if
        path:find("/mesa/", 1, true)
        or lines:match "__kernel"
        or lines:match "__global"
        or lines:match "get_global_id"
        or lines:match "SPDX.*MIT" and lines:match "#include" and lines:match "kernel"
      then
        return "opencl"
      end
      return "lisp"
    end,
    hlsl = "hlsl",
    wgsl = "wgsl",
    qml = "qml",
    qrc = "xml",
    wxs = "xml",
    jinja = "jinja",
    jinja2 = "jinja",
    j2 = "jinja",
  },
  filename = {
    ["Caddyfile"] = "caddy",
    [".clang-format-ignore"] = "gitignore",
    [".bazelignore"] = "gitignore",
    [".helmignore"] = "gitignore",
    [".yapfignore"] = "gitignore",
    [".codespellignore"] = "gitignore",
    [".lycheeignore"] = "gitignore",
    [".codespellrc"] = "dosini",
    [".shellcheckrc"] = "dosini",

    ["Chart.lock"] = "yaml",
    ["Podfile.lock"] = "yaml",
    ["Gemfile.lock"] = "gemfilelock",
    ["Justfile"] = "just",
    ["justfile"] = "just",
    [".bazelrc"] = "bazelrc",
  },
  pattern = {
    [".*/kubernetes/OWNERS_ALIASES"] = "yaml",
    [".*/kubernetes/cluster/gce/manifests/.*%.manifest"] = "yaml",
    [".*/debian/upstream/metadata"] = "yaml",
    [".*/%.reuse/dep5"] = "debcopyright",
    [".*/nixos%-config/users/mitchellh/ghostty%.linux"] = "ghostty",
    [".*/nixos%-config/users/mitchellh/rofi"] = "rasi",
    [".*/nixos%-config/users/mitchellh/i3status"] = "libconfig",
    [".*/vicinae/figura/.*%.fig"] = "figura",
    [".*/xbyak/sample/.*%.bf"] = "brainfuck",
    [".*/SPIRV%-Headers/include/.*/spirv%.bf"] = "beef",
    [".*/vulkan%-loader/scripts/gn/DEPS"] = "python",
    [".*/freetype/src/autofit/afblue%.hin"] = "c_template",
    [".*/freetype/src/autofit/afblue%.cin"] = "c_template",
    [".*/freetype/builds/unix/freetype2%.in"] = "pkgconfig",
    [".*/libpng/scripts/libpng%-config%-body%.in"] = "sh",
    [".*/requirements/[^/]+%.in"] = "requirements",
    [".*/mesa/docs/mesa3d_theme/static/.*%.css_t"] = "css_template",
    [".*/mesa/src/gallium/drivers/nouveau/.*%.mme"] = "mme",
    [".*/mesa/build%-support/conftest%.dyn"] = "ld",
    [".*/sdl3/src/render/.*%.cg"] = "cg",
    [".*/protobuf/objectivec/Tests/.*%.pddm"] = "objc_template",
    [".*%.desktop%.template"] = "desktop",
    [".*BUILD%.bazel%.template"] = "bzl",

    [".*/kubernetes/staging/src/k8s%.io/apimachinery/pkg/util/strategicpatch/testdata/swagger%-merge%-item%.json"] = "jsonc",
    [".*/kubernetes/staging/src/k8s%.io/kubectl/pkg/explain/test%-swagger%.json"] = "jsonc",
    [".*/vicinae/extra/extension%-boilerplate/assets/package%.json"] = "json_template",
    [".*/hugo%-book/assets/manifest%.json"] = "gotmpl",
    [".*"] = {
      function(_, buf)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local source = table.concat(lines, "\n")
        if #source <= 1048576 and source:match "^%s*[%[{]" and pcall(vim.json.decode, source) then
          return "json"
        end
      end,
      { priority = -math.huge },
    },
    [".*/kubernetes/.*/OWNERS"] = "yaml",
    [".*/kubernetes/.*/OWNERS_ALIASES"] = "yaml",
    [".*/kubernetes/.*/%.import%-restrictions"] = "yaml",
    [".*/kubernetes/.*%.kuberc"] = "yaml",
    [".*/Makefile%.[^/]+"] = "make",
    [".*/include/gsl/[^/.]+"] = "cpp",
    [".*%.([%w]+)%.in"] = function(path, bufnr)
      return vim.filetype.match { filename = path:gsub("%.in$", ""), buf = bufnr }
    end,
    [".*/[^/]+%.service"] = unit_type,
    [".*/[^/]+%.timer"] = unit_type,
    [".*/[^/]+%.socket"] = unit_type,
    [".*/[^/]+%.target"] = unit_type,
    [".*/[^/]+%.path"] = unit_type,
    [".*/[^/]+%.mount"] = unit_type,
  },
}

local ns = vim.api.nvim_create_namespace "massivim.jsonl"
local function validate(buf)
  if vim.bo[buf].filetype ~= "jsonl" then
    vim.diagnostic.reset(ns, buf)
    return
  end
  local errors = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match "%S" then
      local ok = pcall(vim.json.decode, line)
      if not ok then
        errors[#errors + 1] = {
          lnum = i - 1,
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          source = "jsonl",
          message = "Invalid JSON record on this line",
        }
      end
    end
  end
  vim.diagnostic.set(ns, buf, errors)
end
vim.api.nvim_create_autocmd("FileType", {
  pattern = "jsonl",
  callback = function(ev)
    vim.bo[ev.buf].syntax = "json"
    validate(ev.buf)
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
      buffer = ev.buf,
      callback = function()
        validate(ev.buf)
      end,
    })
  end,
})
-- Metal has C-family syntax highlighting, but no claimed Tree-sitter grammar or
-- SDK-backed semantics. This is a fallback, tracked separately in coverage.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "metal",
  callback = function()
    vim.bo.syntax = "metal"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "opencl",
  callback = function()
    vim.bo.syntax = "opencl"
  end,
})
