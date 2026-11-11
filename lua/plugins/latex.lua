return {
  {
    "lervag/vimtex",
    ft = { "tex", "plaintex", "bib" },
    init = function()
      -- The template uses fontspec, so it must be XeLaTeX.
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        callback = 1,
        continuous = 1,
        executable = "latexmk",
        build_dir = "build",
        options = {
          "-xelatex",
          "-synctex=1",
          "-interaction=nonstopmode",
          "-file-line-error",
        },
      }

      -- Output directory and engine also live in .latexmkrc, so CLI, VS Code,
      -- and VimTeX all build into the same place.
      if vim.fn.executable "zathura" == 1 then
        vim.g.vimtex_view_method = "zathura"
      else
        vim.g.vimtex_view_method = "general"
        vim.g.vimtex_view_general_viewer = "xdg-open"
      end

      vim.g.vimtex_quickfix_mode = 0
      vim.g.tex_flavor = "latex"
    end,
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tex", "plaintex", "bib" },
        callback = function()
          vim.opt_local.spell = true
          vim.opt_local.spelllang = { "en_gb", "en_us" }
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
        end,
      })
    end,
  },
}
