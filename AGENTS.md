# MASSIVIM Agent Notes

- MASSIVIM is a portable NvChad-based Neovim config. NixOS is the primary target; WSL and other non-NixOS setups are supported too.
- On NixOS, LSPs, formatters, and related tools come from system packages. If a dependency changes, update the copy-paste NixOS package block in `README.md`.
- Optional AI coding CLIs must stay documented separately as `unstable.*` packages. Be explicit that only those named packages come from `nixos-unstable`.
- On WSL and other non-NixOS systems, Mason installs LSPs and formatters on first launch. Only surface manual runtime requirements when the task touches setup or platform docs.
- Extra reference material that is not needed every turn lives in `docs/agent-context.md`.
