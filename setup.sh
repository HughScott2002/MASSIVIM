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
if command -v brew &>/dev/null; then
  PKG="brew"
elif command -v apt &>/dev/null; then
  PKG="apt"
elif command -v dnf &>/dev/null; then
  PKG="dnf"
elif command -v pacman &>/dev/null; then
  PKG="pacman"
elif command -v nix-env &>/dev/null; then
  PKG="nix"
else
  echo "No supported package manager found. Install these manually:"
  echo "  neovim (>= 0.11), git, gcc, make, ripgrep, fd, lazygit, nodejs, npm, unzip, curl"
  echo "  luarocks, luajit, imagemagick (for image.nvim)"
  exit 1
fi

install_pkg() {
  echo "-> Installing: $*"
  case $PKG in
    apt)    sudo apt install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
    brew)   brew install "$@" ;;
    nix)    for p in "$@"; do nix-env -iA "nixpkgs.$p"; done ;;
  esac
}

# Core dependencies
case $PKG in
  apt)
    sudo apt update
    install_pkg git gcc make ripgrep fd-find nodejs npm unzip curl luarocks imagemagick libmagickwand-dev
    # apt neovim is usually too old — check version
    if ! command -v nvim &>/dev/null || [[ "$(nvim --version | head -1 | grep -oP '\d+\.\d+')" < "0.11" ]]; then
      echo "-> neovim >= 0.11 required. apt version is too old."
      echo "   Install from: https://github.com/neovim/neovim/releases or via brew/snap"
    fi
    ;;
  dnf)
    install_pkg neovim git gcc make ripgrep fd-find nodejs npm unzip curl luarocks ImageMagick ImageMagick-devel
    ;;
  pacman)
    install_pkg neovim git gcc make ripgrep fd nodejs npm unzip curl luarocks imagemagick
    ;;
  brew)
    install_pkg neovim git gcc make ripgrep fd node unzip curl luarocks luajit imagemagick
    ;;
  nix)
    echo "-> Installing via nix-env..."
    install_pkg neovim git gcc gnumake ripgrep fd lazygit nodejs luarocks luajit imagemagick
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
    nix)    ;; # already installed above
  esac
fi

# tree-sitter CLI
if ! command -v tree-sitter &>/dev/null; then
  echo "-> Installing tree-sitter CLI via npm..."
  sudo npm install -g tree-sitter-cli
fi

# magick luarock (for image.nvim)
echo ""
echo "-> Installing magick luarock for image.nvim..."
if command -v luarocks &>/dev/null; then
  # Set PKG_CONFIG_PATH for ImageMagick if installed via nix
  if [ "$PKG" = "nix" ]; then
    MAGICK_PC=$(find /nix/store -name "MagickWand.pc" 2>/dev/null | head -1)
    if [ -n "$MAGICK_PC" ]; then
      export PKG_CONFIG_PATH="$(dirname "$MAGICK_PC"):${PKG_CONFIG_PATH:-}"
      echo "   Set PKG_CONFIG_PATH for nix ImageMagick: $(dirname "$MAGICK_PC")"
      echo ""
      echo "   *** Add this to your shell config (~/.bashrc or ~/.zshrc): ***"
      echo "   export PKG_CONFIG_PATH=\"$(dirname "$MAGICK_PC"):\$PKG_CONFIG_PATH\""
      echo ""
    fi
  fi
  luarocks --local --lua-version=5.1 install magick
else
  echo "   luarocks not found — skipping. image.nvim will not work."
fi

echo ""
echo "=== Done! ==="
echo "Open nvim and Mason will auto-install LSP servers and formatters."
echo "Run :Mason to check progress."
echo ""
echo "NOTE: image.nvim requires a terminal with Kitty graphics protocol support"
echo "      (Kitty, WezTerm, or compatible). It will not render images in other terminals."
