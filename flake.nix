{
  description = "Aee's unified Dev flake: Home-Manager + DevShells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ home-manager.overlay ];
        };
      in {
        # Global devShells: default and language-specific
        devShells = {
          # The "default" shell used when no name is given
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              elixir erlang
              python3
              nodejs
              yarn
              docker
              docker-compose
            ];
            shellHook = ''
              export EDITOR=zed
              echo "🚀 Welcome to Aee's dev shell!"
            '';
          };

          # Language-specific shells for per-project overrides
          python = pkgs.mkShell {
            buildInputs = with pkgs; [ python3 pipenv poetry ];
            shellHook = ''
              echo "🐍 Python shell with isolated env tools"
            '';
          };

          node = pkgs.mkShell {
            buildInputs = with pkgs; [ nodejs yarn pnpm ];
            shellHook = ''
              echo "🔧 Node.js shell with Yarn and PNPM"
            '';
          };

          # Example: Add a project-specific shell by creating a flake
          # in that project folder with its own devShells.<projectName> entry.
        };

        # Home-Manager config for user 'aee'
        homeConfigurations.aee = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [ ({ config, pkgs, ... }: {
            home.username = "aee";
            home.homeDirectory = "/home/aee";

            home.sessionVariables = {
              LANG = "en_PH.UTF-8";
              TZ = "Asia/Manila";
            };

            # Fonts & UI apps
            home.packages = with pkgs; [ ttf-jetbrains-mono noto-fonts ];
            home.packages = home.packages ++ with pkgs; [
              google-chrome brave zed sublime-merge dbeaver
              obs-studio inkscape flatpak
            ];

            # CLI tools & runtimes
            home.packages = home.packages ++ with pkgs; [
              git neovim fastfetch docker docker-compose
              elixir python3 nodejs yarn
            ];

            programs.zsh = {
              enable = true;
              enableCompletion = true;
              ohMyZsh.enable = true;
              ohMyZsh.theme = "agnoster";
              ohMyZsh.plugins = [ "git" "docker" "npm" "python" "yarn" ];
            };

            services.docker.enable = true;
            users.users.aee.extraGroups = [ "docker" ];

            programs.flatpak.enable = true;

            environment.variables = {
              EDITOR = "zed";
            };
          }) ];
        };
      }
    );
}
