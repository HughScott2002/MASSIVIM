require("nvchad.configs.lspconfig").defaults()

local inlay_hint_method = vim.lsp.protocol.Methods.textDocument_inlayHint

local function has_inlay_hints(bufnr)
  return not vim.tbl_isempty(vim.lsp.get_clients {
    bufnr = bufnr,
    method = inlay_hint_method,
  })
end

local function toggle_buffer_inlay_hints(bufnr)
  if not has_inlay_hints(bufnr) then
    vim.notify("No inlay hints available for this buffer", vim.log.levels.INFO)
    return
  end

  vim.lsp.inlay_hint.enable(
    not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr },
    { bufnr = bufnr }
  )
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, {
      buffer = args.buf,
      desc = "LSP Hover",
    })

    vim.keymap.set("n", "<leader>ih", function()
      toggle_buffer_inlay_hints(args.buf)
    end, {
      buffer = args.buf,
      desc = "Toggle inlay hints in buffer",
    })

    -- clangd registers :LspClangdSwitchSourceHeader on attach
    local ft = vim.bo[args.buf].filetype
    if ft == "c" or ft == "cpp" then
      vim.keymap.set("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", {
        buffer = args.buf,
        desc = "Switch source/header (C/C++)",
      })
    end
  end,
})

local servers = {
  "html",
  "cssls",
  "jsonls",
  "eslint",
  "ts_ls",
  "tailwindcss",
  "gopls",
  "zls",
  "pyright",
  "rust_analyzer",
  "nil_ls",
  "yamlls",
  "sqls",
  "bashls",
  "clangd",
  "cmake",
  "texlab",
  "dockerls",
  "lemminx",
  "lua_ls",
  "emmet_ls",
  "roslyn_ls",
  "denols",
  "phpactor",
  -- roslyn_ls requires .NET SDK (install manually on WSL)
}

vim.lsp.enable(servers)

vim.lsp.config("denols", {
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { "deno.json", "deno.jsonc" })
    if root then on_dir(root) end
  end,
})

vim.lsp.config("ts_ls", {
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if vim.fs.root(fname, { "deno.json", "deno.jsonc" }) then return end
    local root = vim.fs.root(fname, { "package.json", "tsconfig.json", "jsconfig.json" })
    if root then on_dir(root) end
  end,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
      },
    },
  },
})

-- Lua: recognize vim global
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

-- Go: format with gofumpt, prefer goimports, and surface staticcheck findings.
-- These are gopls settings, so they apply on both NixOS and Mason installs.
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      gofumpt = true,
      staticcheck = true,
      analyses = { unusedparams = true },
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

-- Rust: use clippy on save and keep the settings on the current schema.
-- checkOnSave stays a boolean; the command lives in check.command.
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      checkOnSave = true,
      check = { command = "clippy" },
      procMacro = { enable = true },
      inlayHints = {
        bindingModeHints = { enable = false },
        chainingHints = { enable = true },
        closingBraceHints = { enable = true, minLines = 25 },
        closureReturnTypeHints = { enable = "never" },
        lifetimeElisionHints = { enable = "never", useParameterNames = false },
        maxLength = 25,
        parameterHints = { enable = true },
        reborrowHints = { enable = "never" },
        renderColons = true,
        typeHints = {
          enable = true,
          hideClosureInitialization = false,
          hideNamedConstructor = false,
        },
      },
    },
  },
})

-- YAML: schema associations
vim.lsp.config("yamlls", {
  before_init = function(_, config)
    config.settings.yaml.schemas = vim.tbl_deep_extend(
      "force",
      config.settings.yaml.schemas or {},
      require("schemastore").yaml.schemas()
    )
  end,
  settings = {
    yaml = {
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.yml",
      },
      format = { enable = true },
      validate = true,
      schemaStore = { enable = false, url = "" },
    },
  },
})

-- Emmet: enable in JSX/TSX
vim.lsp.config("emmet_ls", {
  filetypes = {
    "html", "css", "scss", "less",
    "javascriptreact", "typescriptreact",
    "jsx", "tsx",
  },
  init_options = {
    includeLanguages = {
      javascriptreact = "html",
      typescriptreact = "html",
    },
  },
})

-- clangd: background index, clang-tidy, IWYU header insertion
-- Language standards are NOT set here. clangd reads them per file from
-- compile_commands.json / compile_flags.txt, with ~/.config/clangd/config.yaml
-- as the per-language fallback for scratch files. A single -std in this
-- config would be applied to C and C++ alike and break one of them.
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders=true",
    "--fallback-style=llvm",
  },
  root_markers = {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    "CMakeLists.txt",
    "Makefile",
    "meson.build",
    "build.ninja",
    ".git",
  },
  capabilities = {
    textDocument = {
      completion = { editsNearCursor = true },
    },
  },
  -- Drop lspconfig's deprecated clangd offsetEncoding extension; Neovim 0.12
  -- negotiates position encodings through general.positionEncodings (LSP 3.17).
  before_init = function(params)
    if params.capabilities then
      params.capabilities.offsetEncoding = nil
    end
  end,
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
})

-- JSON: schema associations
vim.lsp.config("jsonls", {
  before_init = function(_, config)
    config.settings.json.schemas = config.settings.json.schemas or {}
    vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
  end,
  settings = {
    json = {
      schemas = {
        { fileMatch = { "package.json" }, url = "https://json.schemastore.org/package.json" },
        { fileMatch = { "tsconfig*.json" }, url = "https://json.schemastore.org/tsconfig.json" },
      },
      format = { enable = true },
      validate = { enable = true },
    },
  },
})

-- Optional language tools are system-managed on NixOS. Missing tools get one
-- notice on the relevant filetype, never an install attempt during startup.
local optional = {
  dartls = { "dart", { "dart" } },
  astro = { "astro-ls", { "astro" } },
  sourcekit = { "sourcekit-lsp", { "swift" } },
  qmlls = { "qmlls", { "qml", "qmljs" } },
  wgsl_analyzer = { "wgsl-analyzer", { "wgsl" } },
  powershell_es = { "pwsh", { "ps1" } },
  kotlin_language_server = { "kotlin-language-server", { "kotlin" } },
  terraformls = { "terraform-ls", { "terraform", "terraform-vars" } },
  glsl_analyzer = { "glsl_analyzer", { "glsl", "vert", "frag", "geom", "comp" } },
  ruby_lsp = { "ruby-lsp", { "ruby", "eruby" } },
  taplo = { "taplo", { "toml" } },
  mesonlsp = { "mesonlsp", { "meson" } },
}
vim.lsp.config("sourcekit", {
  filetypes = { "swift" },
  -- Swift Foundation 6.2.4 traps converting this host's local time zone in
  -- its logger. UTC avoids the reproduced trap without changing system time.
  cmd_env = vim.fn.filereadable "/etc/NIXOS" == 1 and { TZ = "UTC" } or nil,
})
if vim.fn.filereadable "/etc/NIXOS" == 1 then
  vim.lsp.config("ruby_lsp", {
    cmd = function(dispatchers, config)
      local gemfile = config.root_dir and config.root_dir .. "/Gemfile"
      -- The packaged gems are already installed. Prevent Ruby LSP's launcher
      -- from downloading a new composed bundle during NixOS buffer startup.
      local environment = { BUNDLE_GEMFILE = gemfile and vim.fn.filereadable(gemfile) == 1 and gemfile or "/dev/null" }
      return vim.lsp.rpc.start({ "ruby-lsp" }, dispatchers, { cwd = config.root_dir, env = environment })
    end,
  })
end

vim.lsp.config("kotlin_language_server", {
  init_options = { storagePath = vim.fn.stdpath("cache") .. "/kotlin" },
  before_init = function(params, config)
    local storage = vim.fn.stdpath("cache") .. "/kotlin/" .. vim.fn.sha256(config.root_dir or "scratch")
    vim.fn.mkdir(storage, "p")
    -- The upstream nil storagePath becomes [] in JSON. This server requires an object.
    config.init_options = { storagePath = storage }
    params.initializationOptions = config.init_options
  end,
})
vim.lsp.config("astro", {
  before_init = function(params, config)
    local candidates = { require("lspconfig.util").get_typescript_server_path(config.root_dir) }
    local executable = vim.fn.exepath "tsserver"
    local real = executable ~= "" and vim.uv.fs_realpath(executable)
    if real then
      local prefix = vim.fs.dirname(vim.fs.dirname(real))
      candidates[#candidates + 1] = prefix .. "/lib"
      candidates[#candidates + 1] = prefix .. "/lib/node_modules/typescript/lib"
    end
    for _, package in ipairs { "typescript-language-server", "astro-language-server" } do
      candidates[#candidates + 1] = vim.fn.stdpath("data") .. "/mason/packages/" .. package .. "/node_modules/typescript/lib"
    end
    if vim.g.tsdk then table.insert(candidates, 1, vim.g.tsdk) end
    for _, path in ipairs(candidates) do
      if path ~= "" and vim.fn.filereadable(path .. "/tsserverlibrary.js") == 1 then
        config.init_options = { typescript = { tsdk = path } }
        params.initializationOptions = config.init_options
        return
      end
    end
    vim.notify("Astro requires TypeScript <=6 with tsserverlibrary.js; install the documented SDK or set vim.g.tsdk", vim.log.levels.ERROR)
  end,
})

-- Use PSES's Nix wrapper; elsewhere lspconfig discovers the Mason bundle.
if vim.fn.executable "powershell-editor-services" == 1 then
  vim.lsp.config("powershell_es", { cmd = { "powershell-editor-services", "-Stdio", "-HostName nvim", "-HostProfileId 0", "-HostVersion 1.0.0", "-LogLevel Information", "-LogPath " .. vim.fn.stdpath("cache") .. "/powershell", "-SessionDetailsPath " .. vim.fn.stdpath("cache") .. "/powershell-session.json" } })
else
  local bundle = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services"
  if vim.fn.isdirectory(bundle .. "/PowerShellEditorServices") == 1 then
    vim.lsp.config("powershell_es", { bundle_path = bundle })
  end
end
for server, tool in pairs(optional) do
  if vim.fn.executable(tool[1]) == 1 then
    vim.lsp.enable(server)
  else
    vim.api.nvim_create_autocmd("FileType", {
      pattern = tool[2], once = true,
      callback = function() vim.notify("Install " .. tool[1] .. " for " .. server .. " (see language-coverage.md)", vim.log.levels.WARN) end,
    })
  end
end
