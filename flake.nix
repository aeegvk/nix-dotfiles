{
  description = "Aee’s unified Dev flake: Home-Manager + DevShells";

  inputs = {
    # 1) Pin nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # 2) Pin Home-Manager and wire it to the same nixpkgs
    home-manager = {
      url                = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      # Import pkgs with the HM overlay and allow unfree (for Chrome, etc.)
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Your user’s Home-Manager configuration
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
              google-chrome brave zed sublime-merge dbeaver
              obs-studio inkscape flatpak
              git neovim fastfetch docker docker-compose
              elixir python3 nodejs yarn
            ];

            # Drop your helper scripts into ~/bin
            home.file = {
              "bin/install-nix.sh" = {
                text       = builtins.readFile ./install-nix.sh;
                executable = true;
              };
            };

            # Zsh & Oh My Zsh
            programs.zsh = {
              enable           = true;
              enableCompletion = true;
              syntaxHighlighting.enable = true;
            };

          })
        ];
      };
    in {
      # ───────────────────────────────────────────────────────────────────────────
      # A) Top-level Home-Manager config for your CLI call
      # ───────────────────────────────────────────────────────────────────────────
      homeConfigurations = {
        aee = hmConfig;
      };

      # ───────────────────────────────────────────────────────────────────────────
      # B) Expose the Home-Manager CLI & packages so activation can install/remove
      # ───────────────────────────────────────────────────────────────────────────
      apps.${system}.home-manager     = pkgs.home-manager;
      packages.${system}.home-manager = pkgs.home-manager;

      # ───────────────────────────────────────────────────────────────────────────
      # C) Global devShells you can `nix develop ~/dotfiles#default|python|node`
      # ───────────────────────────────────────────────────────────────────────────
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          elixir erlang python3 nodejs yarn docker docker-compose
        ];
        shellHook = ''
          export EDITOR=zed
          echo "🚀 Aee’s global dev shell"
        '';
      };

      devShells.${system}.python = pkgs.mkShell {
        buildInputs = with pkgs; [ python3 pipenv poetry ];
        shellHook  = "echo \"🐍 Python shell with pipenv & poetry\"";
      };

      devShells.${system}.node = pkgs.mkShell {
        buildInputs = with pkgs; [ nodejs yarn pnpm ];
        shellHook  = "echo \"🔧 Node.js shell with Yarn & PNPM\"";
      };
    };
}
