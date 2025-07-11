{
  description = "Aee’s unified Dev flake: Home-Manager + DevShells";

  inputs = {
    # Pin nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Pin Home-Manager and wire it to the same nixpkgs
    home-manager = {
      url                = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";

      # Import pkgs with the HM overlay and allow unfree (for Chrome, etc.)
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Enable unstable pkgs
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # User’s Home-Manager configuration
      hmConfig = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ({ config, pkgs, lib, ... }: {
            # Basic user info
            home.username      = "aee";
            home.homeDirectory = "/home/aee";
            home.stateVersion  = "23.11";

            # Packages & GUI Apps
            home.packages = with pkgs; [
              noto-fonts
              google-chrome brave unstable.zed-editor sublime-merge dbeaver
              obs-studio inkscape flatpak
              git neovim fastfetch docker docker-compose
              elixir python3 nodejs yarn
              fish gimp
            ];

            # Drop helper scripts into ~/bin
            home.file = {
              "bin/install-nix.sh" = {
                text       = builtins.readFile ./install-nix.sh;
                executable = true;
              };
            };

            programs.fish.enable = true;
            programs.fish.shellInit = ''
              # add Nix single-user profile to PATH
              set -gx PATH $HOME/.nix-profile/bin $PATH
            '';

            # Keep bash as login-shell but auto‐exec fish on interactive starts
            programs.bash.enable = true;
            programs.bash.initExtra = ''
              if [ -n "$PS1" ] && [ -t 1 ] &&
                  ps -o comm= -p $PPID | grep -qv fish; then
                exec ${pkgs.fish}/bin/fish --login
              fi
            '';
            # ───────────────────────────────────────────────────────────────

          })
        ];
      };
    in {
      # ───────────────────────────────────────────────────────────────────────────
      # Top-level Home-Manager config for your CLI call
      # ───────────────────────────────────────────────────────────────────────────
      homeConfigurations = {
        aee = hmConfig;
      };

      # ───────────────────────────────────────────────────────────────────────────
      # Expose the Home-Manager CLI & packages so activation can install/remove
      # ───────────────────────────────────────────────────────────────────────────
      apps.${system}.home-manager     = pkgs.home-manager;
      packages.${system}.home-manager = pkgs.home-manager;

      # ───────────────────────────────────────────────────────────────────────────
      # Global devShells you can `nix develop ~/dotfiles#default|python|node`
      # ───────────────────────────────────────────────────────────────────────────
      devShells.${system} = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [ elixir erlang python3 nodejs yarn docker docker-compose ];
          shell = pkgs.fish;
          shellHook = ''
            export EDITOR=zeditor
            echo "🚀 Aee’s global dev shell"
            exec ${pkgs.fish}/bin/fish --login
          '';
        };

        python = pkgs.mkShell {
          shell = pkgs.fish;
          buildInputs = with pkgs; [ python3 pipenv unstable.uv ];
          shellHook  = ''
            echo "🐍 Python shell with pipenv & uv"
            exec ${pkgs.fish}/bin/fish --login
          '';
        };

        node = pkgs.mkShell {
          shell = pkgs.fish;
          buildInputs = with pkgs; [ nodejs yarn pnpm ];
          shellHook  = ''
            echo "🔧 Node.js shell with Yarn & PNPM"
            exec ${pkgs.fish}/bin/fish --login
          '';
        };
      };
    };
}
