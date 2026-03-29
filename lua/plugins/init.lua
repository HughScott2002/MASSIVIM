return {
  -- Conform (formatter)
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- LSP Config
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "typescript", "tsx", "javascript", "css", "scss", "html",
        "rust", "go", "python", "java",
        "yaml", "json", "jsonc", "bash", "lua", "nix", "sql",
        "dockerfile", "make", "cmake", "xml",
        "markdown", "markdown_inline", "toml", "gitignore",
        "graphql", "proto",
        "vim", "vimdoc", "regex",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- Diffview (git diff viewer)
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    opts = {},
  },

  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- REST client
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    opts = {},
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview" },
    ft = "markdown",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

  -- Harpoon (file bookmarks)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
  },

  -- Flash (motion/navigation)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Todo Comments
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- Trouble (diagnostics list)
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
  },

  -- Auto-close/rename HTML/JSX/TSX tags
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },

  -- Import cost (show bundle size of JS/TS imports)
  {
    "barrett-ruth/import-cost.nvim",
    build = "sh scripts/install.sh pnpm",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    config = function() end,
  },

  -- nvim-tree: show all files including gitignored
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filters = {
        dotfiles = false,
        git_ignored = false,
      },
    },
  },

  -- Telescope: show hidden/dotfiles and gitignored files
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        file_ignore_patterns = { "%.git/" },
      },
      pickers = {
        find_files = {
          hidden = true,
          no_ignore = true,
        },
      },
    },
  },

  -- CSS/Hex color preview
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufReadPost",
    opts = {
      "css", "scss", "html", "javascript", "javascriptreact",
      "typescript", "typescriptreact", "lua", "nix",
    },
  },

  -- Inline git blame (extends NVChad's gitsigns)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
    },
  },

  -- Rainbow bracket colorization
  {
    "hiphish/rainbow-delimiters.nvim",
    event = "BufReadPost",
    config = function()
      require("rainbow-delimiters.setup").setup {}
    end,
  },

  -- Path autocomplete (add cmp-path source)
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      table.insert(opts.sources, { name = "path" })
    end,
  },

  -- Java LSP (special setup)
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
      require("jdtls").start_or_attach {
        cmd = { "jdtls", "-data", vim.fn.expand "~/.cache/jdtls/workspace/" .. project_name },
        root_dir = vim.fs.root(0, { ".git", "pom.xml", "build.gradle", "mvnw", "gradlew" }),
      }
    end,
  },

  -- Inline image display (requires Kitty graphics protocol terminal)
  {
    "3rd/image.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      backend = "kitty",
      processor = "magick_rock",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          floating_windows = false,
          filetypes = { "markdown", "vimwiki" },
        },
        neorg = { enabled = false },
        typst = { enabled = false },
        html = { enabled = false },
        css = { enabled = false },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = true,
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif", "*.svg", "*.bmp", "*.tiff", "*.ico" },
    },
  },
}
