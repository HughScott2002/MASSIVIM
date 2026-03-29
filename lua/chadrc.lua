---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "onedark",

  hl_override = {
    Normal = { bg = "#000000" },
    NormalNC = { bg = "#000000" },
    NormalFloat = { bg = "#000000" },
    NvimTreeNormal = { bg = "#000000" },
    NvimTreeNormalNC = { bg = "#000000" },
    NvimTreeWinSeparator = { bg = "#000000", fg = "#000000" },
    StatusLine = { bg = "#000000" },
    TbLineFill = { bg = "#000000" },
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.ui = {
  statusline = {
    theme = "vscode",
  },
  tabufline = {
    lazyload = false,
  },
}

M.nvdash = { load_on_startup = true }

-- On NixOS, LSPs/formatters are system-installed; elsewhere Mason handles them
local is_nixos = vim.fn.filereadable "/etc/NIXOS" == 1

M.mason = {
  pkgs = is_nixos and {} or {
    -- LSP servers
    "lua-language-server",
    "html-lsp",
    "css-lsp",
    "json-lsp",
    "eslint-lsp",
    "typescript-language-server",
    "tailwindcss-language-server",
    "gopls",
    "pyright",
    "rust-analyzer",
    "yaml-language-server",
    "sqls",
    "bash-language-server",
    "cmake-language-server",
    "dockerfile-language-server",
    "lemminx",
    "emmet-ls",

    -- Formatters
    "stylua",
    "prettier",
    "black",
    "google-java-format",
    "rustfmt",
    "gofumpt",
  },
}

return M
