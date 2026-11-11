#!/usr/bin/env bash
# Run a Neovim command with copied mutable plugin/parser/cache state.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
AUDIT_HOME=$(mktemp -d)
cleanup() {
  if test -n "${MASSIVIM_LOG_DIR:-}"; then
    mkdir -p "$MASSIVIM_LOG_DIR"
    cp -a "$AUDIT_HOME/state/." "$MASSIVIM_LOG_DIR/"
  fi
  rm -rf "$AUDIT_HOME"
}
trap cleanup EXIT
mkdir -p "$AUDIT_HOME/config" "$AUDIT_HOME/data/nvim" "$AUDIT_HOME/state" "$AUDIT_HOME/cache"
cp -a "$ROOT" "$AUDIT_HOME/config/nvim"
for name in lazy base46 lazy-rocks site; do
  if test "$name" = site && test -n "${MASSIVIM_COLD:-}"; then continue; fi
  if test -e "$HOME/.local/share/nvim/$name"; then cp -a "$HOME/.local/share/nvim/$name" "$AUDIT_HOME/data/nvim/$name"; fi
done
export XDG_CONFIG_HOME="$AUDIT_HOME/config" XDG_DATA_HOME="$AUDIT_HOME/data"
export XDG_STATE_HOME="$AUDIT_HOME/state" XDG_CACHE_HOME="$AUDIT_HOME/cache" MASSIVIM_AUDIT=1
nvim --headless --cmd 'set nomodeline noswapfile noundofile' "$@"
