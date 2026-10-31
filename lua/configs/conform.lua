local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    scss = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    graphql = { "prettier" },
    rust = { "rustfmt" },
    zig = { "zigfmt" },
    go = { "goimports", "gofumpt" },
    python = { "ruff_organize_imports", "ruff_format" },
    nix = { "nixfmt" },
    java = { "google-java-format" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    php = { "php_cs_fixer" },
  },

  format_on_save = function(bufnr)
    -- Prettier removes Markdown's two-space hard-break syntax. Keep explicit
    -- formatting available through <leader>fm, but never alter prose on save.
    if vim.bo[bufnr].filetype == "markdown" then return nil end

    return {
      timeout_ms = 1000,
      lsp_fallback = true,
    }
  end,
}

return options
