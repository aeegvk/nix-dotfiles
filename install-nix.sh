#!/usr/bin/env bash
# install-nix.sh — Installs Nix (multi-user) and enables flakes in ~/.config/nix/nix.conf
set -euo pipefail

# 1) Bail out if already installed
if command -v nix &>/dev/null; then
  echo "✨ Nix is already installed at: $(command -v nix)"
  exit 0
fi

# 2) Ensure we’re on Linux
OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
  echo "❌ Unsupported OS: $OS. This installer only supports Linux."
  exit 1
fi

# 3) Run the official installer in daemon mode
echo "🚀 Installing Nix (multi-user daemon mode)…"
curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install \
  | sh -s -- --daemon

# 4) Enable experimental-features (flakes) in user nix.conf
CONFIG_DIR="${HOME}/.config/nix"
CONFIG_FILE="${CONFIG_DIR}/nix.conf"

echo "🔧 Configuring $CONFIG_FILE for flakes…"
mkdir -p "$CONFIG_DIR"

# Idempotently add the line if it’s not already present
if grep -qE '^\s*experimental-features\s*=' "$CONFIG_FILE" 2>/dev/null; then
  echo "  • experimental-features already set in $CONFIG_FILE"
else
  echo "  • Adding flakes support to $CONFIG_FILE"
  {
    echo ""
    echo "# Enable Nix CLI & flakes"
    echo "experimental-features = nix-command flakes"
  } >> "$CONFIG_FILE"
fi

# 5) Post-install instructions
cat <<EOF

✅ Nix installed and flakes enabled!

Next steps:
  1) Source your profile now:
       source /etc/profile.d/nix.sh
     (or just close & reopen your terminal)

  2) Verify:
       nix --version
       nix flake --help

Happy hacking! 🚀
EOF

exit 0
