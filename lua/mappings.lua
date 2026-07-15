require "nvchad.mappings"

local map = vim.keymap.set

-- General
map({ "n", "i", "v" }, "<C-z>", "<cmd>undo<CR>", { desc = "Undo" })
map({ "n", "i", "v" }, "<C-S-z>", "<cmd>redo<CR>", { desc = "Redo" })
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- LazyGit
map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Open LazyGit" })

-- Diffview
map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Git diff view" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Close diff view" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "File git history" })

-- Harpoon
map("n", "<leader>ha", function()
  require("harpoon"):list():add()
end, { desc = "Harpoon add file" })

map("n", "<leader>hh", function()
  local harpoon = require "harpoon"
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon menu" })

map("n", "<leader>h1", function()
  require("harpoon"):list():select(1)
end, { desc = "Harpoon file 1" })

map("n", "<leader>h2", function()
  require("harpoon"):list():select(2)
end, { desc = "Harpoon file 2" })

map("n", "<leader>h3", function()
  require("harpoon"):list():select(3)
end, { desc = "Harpoon file 3" })

map("n", "<leader>h4", function()
  require("harpoon"):list():select(4)
end, { desc = "Harpoon file 4" })

-- Flash
map({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash jump" })

map({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash treesitter" })

-- Trouble diagnostics
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Buffer diagnostics" })

-- Formatting
map("n", "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "Format file" })

map("n", "<leader>iH", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints globally" })

-- Escape terminal mode with Esc Esc (double tap)
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Claude Code
-- map("n", "<leader>cc", function()
--  require("nvchad.term").toggle { pos = "float", id = "claudeCode", cmd = "claude" }
-- end, { desc = "Toggle Claude Code" })

-- Codex
map("n", "<leader>cc", function()
  require("nvchad.term").toggle { pos = "float", id = "codex", cmd = "codex" }
end, { desc = "Toggle Codex" })

-- Openrouter
map("n", "<leader>co", function()
  require("nvchad.term").toggle { pos = "float", id = "opencode", cmd = "opencode" }
end, { desc = "Toggle Opencode" })

-- Terminal
map("n", "<leader>tt", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "Toggle floating terminal" })

map("n", "<leader>th", function()
  require("nvchad.term").toggle { pos = "sp", id = "hTerm" }
end, { desc = "Toggle horizontal terminal" })

-- Markdown Preview
map("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Toggle markdown preview" })

-- Git blame toggle
map("n", "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle git blame" })

-- Toggle hidden/ignored files in nvim-tree
map("n", "<leader>ti", function()
  require("nvim-tree.api").tree.toggle_gitignore_filter()
end, { desc = "Toggle gitignored files" })

map("n", "<leader>t.", function()
  require("nvim-tree.api").tree.toggle_hidden_filter()
end, { desc = "Toggle dotfiles" })

-- Todo Comments
map("n", "<leader>td", "<cmd>TodoTelescope<CR>", { desc = "Search TODOs" })
