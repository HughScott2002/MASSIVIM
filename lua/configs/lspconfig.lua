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

-- Rust: use clippy on save
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = true,
      check = { command = "clippy" },
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
    "--function-arg-placeholders",
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
