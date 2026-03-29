require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "jsonls",
  "eslint",
  "ts_ls",
  "tailwindcss",
  "gopls",
  "pyright",
  "rust_analyzer",
  "nil_ls",
  "yamlls",
  "sqls",
  "bashls",
  "cmake",
  "dockerls",
  "lemminx",
  "lua_ls",
  "emmet_ls",
}

vim.lsp.enable(servers)

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
      checkOnSave = { command = "clippy" },
    },
  },
})

-- TypeScript: inlay hints
vim.lsp.config("ts_ls", {
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

-- YAML: schema associations
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.yml",
      },
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

-- JSON: schema associations
vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = {
        { fileMatch = { "package.json" }, url = "https://json.schemastore.org/package.json" },
        { fileMatch = { "tsconfig*.json" }, url = "https://json.schemastore.org/tsconfig.json" },
      },
    },
  },
})
