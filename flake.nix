{
  description = "Aee’s unified Dev flake: Home-Manager + DevShells";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ home-manager.overlay ];
        };

        # all your GUI apps, fonts & CLI tools in one list
        myPkgs = with pkgs; [
          ttf-jetbrains-mono noto-fonts
          google-chrome brave zed sublime-merge dbeaver
          obs-studio inkscape flatpak
          git neovim fastfetch docker docker-compose
          elixir python3 nodejs yarn
        ];
      in rec {
        # ───────────────────────────────────────────────────────────────────────────
        # 1) Dev shells you get via `nix develop ~/dotfiles#default`, `#python`, `#node`
        # ───────────────────────────────────────────────────────────────────────────
        devShells.${system} = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ elixir erlang python3 nodejs yarn docker docker-compose ];
            shellHook  = ''
              export EDITOR=zed
              echo "🚀 Welcome to Aee’s global dev shell!"
            '';
          };

          python = pkgs.mkShell {
            buildInputs = with pkgs; [ python3 pipenv poetry ];
            shellHook  = "echo \"🐍 Python shell with pipenv & poetry\"";
          };

          node = pkgs.mkShell {
            buildInputs = with pkgs; [ nodejs yarn pnpm ];
            shellHook  = "echo \"🔧 Node.js shell with Yarn & PNPM\"";
          };
        };

        # ───────────────────────────────────────────────────────────────────────────
        # 2) Home-Manager user config under `homeConfigurations.aee`
        # ───────────────────────────────────────────────────────────────────────────
        homeConfigurations = {
          aee = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            # modules is a list of Home-Manager modules (you can also import .nix files)
            modules = [
              ({ config, pkgs, lib, ... }: {
                # basic identity
                home.username      = "aee";
                home.homeDirectory = "/home/aee";
                home.stateVersion  = "23.11";

                # locale & timezone
                i18n.defaultLocale = "en_PH.UTF-8";
                time.timeZone      = "Asia/Manila";

                # packages & GUI apps
                home.packages = myPkgs;

                # drop these files into your profile
                home.file = {
                  "bin/install-nix.sh" = {
                    text       = builtins.readFile ./install-nix.sh;
                    executable = true;
                  };
                  "repos.txt" = {
                    text = builtins.readFile ./repos.txt;
                  };
                };

                # zsh + Oh My Zsh
                programs.zsh = {
                  enable           = true;
                  enableCompletion = true;
                  ohMyZsh.enable   = true;
                  ohMyZsh.theme    = "agnoster";
                  ohMyZsh.plugins  = [ "git" "docker" "npm" "python" "yarn" ];
                  autosuggestions.enable    = true;
                  syntaxHighlighting.enable = true;
                };

                # docker
                services.docker.enable      = true;
                users.users.aee.extraGroups = [ "docker" ];

                # flatpak
                programs.flatpak.enable = true;

                # default editor
                environment.variables = {
                  EDITOR = "zed";
                };
              })
            ];
          };
        };

        # ───────────────────────────────────────────────────────────────────────────
        # 3) Expose the activationPackage so the CLI can find it
        # ───────────────────────────────────────────────────────────────────────────
        packages = {
          homeConfigurations = {
            aee = homeConfigurations.aee.activationPackage;
          };
        };

        legacyPackages = {
          homeConfigurations = {
            aee = homeConfigurations.aee.activationPackage;
          };
        };
      }
    );
}
