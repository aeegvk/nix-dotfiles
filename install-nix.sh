#!/usr/bin/env bash
# install-nix.sh — Installs Nix (single- or multi-user) and enables flakes.
# Usage: ./install-nix.sh [--single|-s] [--help|-h]
#   --single, -s   => single-user (--no-daemon)
#   --multi,  -m   => multi-user (--daemon)  [default]
#   --help,   -h   => show this help

set -euo pipefail

show_help() {
  cat <<EOF
install-nix.sh

This script installs Nix on Linux in either multi-user (daemon) mode
or single-user mode (no-daemon, for SELinux-enabled systems).

Usage:
  $0 [--single|-s] [--multi|-m] [--help|-h]

Options:
  --single, -s    Single-user install (passes --no-daemon)
  --multi,  -m    Multi-user install (passes --daemon)  [default]
  --help,   -h    Show this help and exit

By default, runs multi-user. After installation, it will also
enable flakes in ~/.config/nix/nix.conf.
EOF
}

# Default to multi-user
INSTALL_MODE="multi"

# Parse args
while (( $# )); do
  case "$1" in
    -s|--single)
      INSTALL_MODE="single"
      shift
      ;;
    -m|--multi)
      INSTALL_MODE="multi"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "❗ Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# 1) Already-installed check
if command -v nix &>/dev/null; then
  echo "✨ Nix is already installed at: $(command -v nix)"
  exit 0
fi

# 2) OS check
OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
  echo "❌ Unsupported OS: $OS. This installer only supports Linux."
  exit 1
fi

# 3) Determine installer flag
if [[ "$INSTALL_MODE" == "single" ]]; then
  INSTALL_FLAG="--no-daemon"
  echo "🚀 Installing Nix (single-user mode)…"
else
  INSTALL_FLAG="--daemon"
  echo "🚀 Installing Nix (multi-user daemon mode)…"
fi

# 4) Run the official installer
curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install \
  | sh -s -- $INSTALL_FLAG

# 5) Enable flakes in per-user config
CONFIG_DIR="${HOME}/.config/nix"
CONFIG_FILE="${CONFIG_DIR}/nix.conf"

echo "🔧 Configuring $CONFIG_FILE for flakes support…"
mkdir -p "$CONFIG_DIR"

if grep -qE '^\s*experimental-features\s*=' "$CONFIG_FILE" 2>/dev/null; then
  echo "  • experimental-features already set in $CONFIG_FILE"
else
  {
    echo ""
    echo "# Enable Nix CLI & flakes"
    echo "experimental-features = nix-command flakes"
  } >> "$CONFIG_FILE"
  echo "  • Added flakes support"
fi

# 6) Post-install instructions
cat <<EOF

✅ Nix installed (${INSTALL_MODE}-user) and flakes enabled!

Next steps:
  • Reload your shell:
      source /etc/profile.d/nix.sh  # for multi-user
      # or
      . ~/.nix-profile/etc/profile.d/nix.sh  # for single-user

  • Verify:
      nix --version
      nix flake --help

Happy hacking! 🚀
EOF
