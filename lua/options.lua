require "nvchad.options"

local o = vim.o

o.cursorlineopt = "both"
o.cursorline = true
o.relativenumber = true
o.number = true
o.scrolloff = 8
o.sidescrolloff = 8
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true
o.wrap = false
o.termguicolors = true
o.signcolumn = "yes"
o.updatetime = 250
o.timeoutlen = 300
o.clipboard = "unnamedplus"
o.undofile = true
o.swapfile = false
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
