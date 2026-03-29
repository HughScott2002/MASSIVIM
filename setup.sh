#!/usr/bin/env bash
# MASSIVIM setup — installs dependencies on non-NixOS systems
# On NixOS, everything is in configuration.nix already. Skip this.
set -euo pipefail

if [ -f /etc/NIXOS ]; then
  echo "NixOS detected — dependencies are managed by configuration.nix. Nothing to do."
  exit 0
fi

echo "=== MASSIVIM Setup ==="
echo "Installing dependencies for non-NixOS systems..."
echo ""

# Detect package manager
if command -v apt &>/dev/null; then
  PKG="apt"
elif command -v dnf &>/dev/null; then
  PKG="dnf"
elif command -v pacman &>/dev/null; then
  PKG="pacman"
elif command -v brew &>/dev/null; then
  PKG="brew"
else
  echo "No supported package manager found. Install these manually:"
  echo "  neovim (>= 0.10), git, gcc, make, ripgrep, fd, lazygit, nodejs, npm, unzip, curl"
  exit 1
fi

install_pkg() {
  echo "-> Installing: $*"
  case $PKG in
    apt)    sudo apt install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
    brew)   brew install "$@" ;;
  esac
}

# Core dependencies
case $PKG in
  apt)
    sudo apt update
    install_pkg neovim git gcc make ripgrep fd-find nodejs npm unzip curl
    ;;
  dnf)
    install_pkg neovim git gcc make ripgrep fd-find nodejs npm unzip curl
    ;;
  pacman)
    install_pkg neovim git gcc make ripgrep fd nodejs npm unzip curl
    ;;
  brew)
    install_pkg neovim git gcc make ripgrep fd node unzip curl
    ;;
esac

# lazygit
if ! command -v lazygit &>/dev/null; then
  echo "-> Installing lazygit..."
  case $PKG in
    apt)
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
      sudo install /tmp/lazygit /usr/local/bin/
      rm /tmp/lazygit /tmp/lazygit.tar.gz
      ;;
    dnf)    install_pkg lazygit ;;
    pacman) install_pkg lazygit ;;
    brew)   install_pkg lazygit ;;
  esac
fi

# tree-sitter CLI
if ! command -v tree-sitter &>/dev/null; then
  echo "-> Installing tree-sitter CLI via npm..."
  sudo npm install -g tree-sitter-cli
fi

echo ""
echo "=== Done! ==="
echo "Open nvim and Mason will auto-install LSP servers and formatters."
echo "Run :Mason to check progress."
