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
        "rust", "go", "python", "java", "c", "cpp",
        "php", "phpdoc",
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

  -- Surround edits: cst<tag>, dst, ysiw<tag>, etc. (tag-aware via treesitter)
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
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

  -- Java LSP (special setup) — wires java-debug + java-test bundles for nvim-dap and neotest-java
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    config = function()
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
      local extensions_root = "/run/current-system/sw/share/vscode/extensions"
      local bundles = {
        vim.fn.glob(extensions_root .. "/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar", true),
      }
      vim.list_extend(
        bundles,
        vim.split(vim.fn.glob(extensions_root .. "/vscjava.vscode-java-test/server/*.jar", true), "\n")
      )
      require("jdtls").start_or_attach {
        cmd = { "jdtls", "-data", vim.fn.expand "~/.cache/jdtls/workspace/" .. project_name },
        root_dir = vim.fs.root(0, { ".git", "pom.xml", "build.gradle", "mvnw", "gradlew" }),
        init_options = { bundles = bundles },
      }
    end,
  },

  -- DAP (debugger)
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      require("nvim-dap-virtual-text").setup {}
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })
    end,
  },

  -- Neotest (test runner) with Java adapter
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "rcasia/neotest-java",
    },
    config = function()
      require("neotest").setup {
        adapters = {
          require("neotest-java") {
            ignore_wrapper = false,
          },
        },
      }
      vim.keymap.set("n", "<leader>tn", function() require("neotest").run.run() end, { desc = "Test nearest" })
      vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Test file" })
      vim.keymap.set("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Test summary" })
      vim.keymap.set("n", "<leader>to", function() require("neotest").output.open { enter = true } end, { desc = "Test output" })
    end,
  },

  -- Spring Boot Tools (STS4 LSP integration: bean nav, application.properties autocomplete)
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
    },
  },

  -- Overseer (run mvn/gradle tasks without leaving nvim)
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen", "OverseerInfo", "OverseerBuild" },
    opts = {},
  },

  -- Database UI (vim-dadbod)
  {
    "tpope/vim-dadbod",
    cmd = { "DB" },
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      "kristijanhusak/vim-dadbod-completion",
    },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = { "tpope/vim-dadbod" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = vim.fn.expand "~/.local/share/db_ui"
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
