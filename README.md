<img width="1768" height="1349" alt="image" src="https://github.com/user-attachments/assets/0de2cf08-b304-43fb-a26b-ab5c66959286" />

# MASSIVIM

My portable NvChad config. Clone it, and it works — NixOS, WSL, Ubuntu, Arch, macOS, whatever.

## Quick Start

```bash
# Back up existing config if needed
mv ~/.config/nvim ~/.config/nvim.bak

# Clone
git clone https://github.com/HughScott2002/MASSIVIM ~/.config/nvim

# Non-NixOS only — install system deps
~/.config/nvim/setup.sh

# Launch
nvim
```

On **NixOS**, LSP servers and formatters are already in `configuration.nix`. Mason is disabled.

On **everything else**, `setup.sh` installs system deps, and Mason auto-installs LSPs/formatters on first launch.

## What's Included

- **Theme**: onedark, pure black background (#000000)
- **LSP**: TypeScript, Rust, Go, Python, Lua, HTML/CSS, JSON, YAML, SQL, Bash, Docker, Java, Nix, Tailwind, Emmet
- **Formatters**: prettier, stylua, rustfmt, gofmt, black, google-java-format (format-on-save)
- **Plugins**: harpoon, flash, lazygit, diffview, trouble, todo-comments, rainbow brackets, image.nvim, import-cost, nvim-ts-autotag, colorizer, markdown-preview, kulala (REST client)
- **Key mappings**: `<leader>gg` lazygit, `<leader>ha` harpoon add, `s` flash jump, `<leader>cc` Claude Code, `<leader>fm` format, `<leader>xx` diagnostics

## Dependencies

### NixOS
Already handled in `configuration.nix` — ripgrep, fd, gcc, lazygit, tree-sitter, stylua, all LSP servers.

### Non-NixOS
Run `setup.sh` or manually install: neovim (>= 0.10), git, gcc, make, ripgrep, fd, lazygit, nodejs, npm, unzip, curl.

## Credits

Built on [NvChad](https://github.com/NvChad/NvChad) v2.5.
