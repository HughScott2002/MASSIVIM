# TODO

## Backlog

- [ ] Go debugging: `nvim-dap-go` + delve. NixOS: delve via system pkgs → update README nix block. WSL: delve via Mason list in `chadrc.lua`. Verify `<leader>db`/`<leader>dc` on Go program, both platforms. Issue: #2

## Done — previous session

- File ownership fixed (chown to hugh:users)
- `lua/chadrc.lua`: Added missing WSL Mason packages
- `lua/plugins/init.lua`: Guarded nil sources, removed FixCursorHold, cleaned trailing empty string
- `lua/configs/lspconfig.lua`: Added roslyn_ls comment
- `CHANGELOG.md` created with record of all changes
