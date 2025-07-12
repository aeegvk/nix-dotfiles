# Aee’s nix-dotfiles & Dev Flake

This repository provides a unified, declarative setup for:

* **Nix** installation (single- or multi-user) with flakes enabled
* **Home Manager** configuration for user shells and GUI apps
* **DevShells** for global, Python, Node.js, and project-specific workflows

---

## 📦 Structure

```text
.
├── flake.nix        # Primary flake definition
├── install-nix.sh   # Helper script to bootstrap Nix & Home Manager
└── README.md        # This document
```

## ⚙️ Prerequisites

* A **Linux** system (other OSes not officially supported here)
* `git`, `curl` available for cloning & installation

## 🚀 Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/yourusername/nix-dotfiles.git ~/nix-dotfiles
cd ~/nix-dotfiles
```

### 2. Install Nix & Home Manager

You can install via the official script, or the Determinate Systems installer:

```bash
# Official installer (multi-user by default):
./install-nix.sh

# Single-user mode (no daemon):
./install-nix.sh --single

# Use Determinate installer with flakes by default:
./install-nix.sh --determinate
```

After running, verify:

```bash
nix --version
nix flake --help
home-manager --version
```

### 3. Activate Home Manager

From the repo root:

```bash
home-manager switch --flake .#aee
```

This will install your user packages, set Fish as your shell, and configure GUI entries.

### 4. Enter a Dev Shell

* **Global shell:** contains Docker, Node, Python, Elixir, etc.

  ```bash
  nix develop
  ```
* **Python shell:** Poetry, Pipenv, UV, and Fish launcher

  ```bash
  nix develop .#python
  ```
* **Node shell:** Yarn, PNPM, Fish launcher

  ```bash
  nix develop .#node
  ```

Inside each shell, environment variables and prompts will guide you.

## 🛠️ Customization

* Edit **`flake.nix`** to add/remove packages, shells, or overlays.
* Place helper scripts in **`home.file."bin/..."`** to have them symlinked into `~/bin`.
* Modify **Fish** or **Bash** init blocks for extra startup logic.

## 📝 Contributing

Feel free to open issues or PRs to improve this setup. Happy hacking! 🚀
