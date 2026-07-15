require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd

-- Force black background on colorscheme change
autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
  end,
})

-- Terminal settings
autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Highlight yanked text
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 200 }
  end,
})

-- Auto-install missing Mason packages on non-NixOS systems.
-- On NixOS the pkgs list is empty (tools come from configuration.nix), so this never fires there.
-- Re-runs on every launch until everything is installed, so it also self-heals
-- once a missing language runtime (go, python3, java, php, ...) is added.
if vim.fn.filereadable "/etc/NIXOS" == 0 then
  autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      local pkg_root = vim.fn.stdpath "data" .. "/mason/packages/"
      for _, pkg in ipairs(require("nvconfig").mason.pkgs) do
        local name = pkg:match "^[^@]+"
        if vim.fn.isdirectory(pkg_root .. name) == 0 then
          vim.notify("Mason: installing missing LSPs/formatters...", vim.log.levels.INFO)
          require("nvchad.mason").install_all()
          return
        end
      end
    end,
  })
end

-- Strip trailing whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos "."
    vim.cmd [[%s/\s\+$//e]]
    vim.fn.setpos(".", save_cursor)
  end,
})
