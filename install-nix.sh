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
enable flakes in ~/.config/nix/nix.conf, reload your shell,
and install the Home Manager CLI via flakes.
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

# 6) Reload the shell’s Nix environment in this session
echo "♻️  Reloading Nix profile into current shell…"
if [[ "$INSTALL_MODE" == "single" ]]; then
  # single-user install
  if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    source "$HOME/.nix-profile/etc/profile.d/nix.sh"
    echo "  • Sourced ~/.nix-profile/etc/profile.d/nix.sh"
  fi
else
  # multi-user install
  if [ -f /etc/profile.d/nix.sh ]; then
    source /etc/profile.d/nix.sh
    echo "  • Sourced /etc/profile.d/nix.sh"
  fi
fi

# 7) Install Home Manager CLI via flakes
echo "🔧 Installing Home Manager CLI via flakes…"
nix profile add home-manager#home-manager
echo "  • Home Manager installed into your user profile"

# 8) Post-install instructions
cat <<EOF

✅ Nix (${INSTALL_MODE}-user) is installed and flakes are enabled!
   Home Manager CLI is ready in your profile.

Next steps:
  • Verify Nix:
      nix --version
      nix flake --help

  • Verify Home Manager:
      home-manager --version

  • To start using Home Manager with your flake:
      cd path/to/your/dotfiles
      home-manager switch --flake .#aee

Happy hacking! 🚀
EOF
