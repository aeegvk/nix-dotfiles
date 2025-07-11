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
        myPkgs = with pkgs; [
          ttf-jetbrains-mono noto-fonts
          google-chrome brave zed sublime-merge dbeaver
          obs-studio inkscape flatpak
          git neovim fastfetch docker docker-compose
          elixir python3 nodejs yarn
        ];
      in {
        # ─────────────────────────────────────────────────────────────────────────
        # Per-user Home-Manager configuration
        # ─────────────────────────────────────────────────────────────────────────
        homeConfigurations.aee = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          home.username      = "aee";
          home.homeDirectory = "/home/aee";
          home.stateVersion  = "23.11";

          i18n.defaultLocale = "en_PH.UTF-8";
          time.timeZone      = "Asia/Manila";

          home.packages = myPkgs;

          # drop installer script into ~/bin
          home.file = {
            "bin/install-nix.sh" = {
              text       = builtins.readFile ./install-nix.sh;
              executable = true;
            };
          };

          programs.zsh = {
            enable           = true;
            enableCompletion = true;
            ohMyZsh.enable   = true;
            ohMyZsh.theme    = "agnoster";
            ohMyZsh.plugins  = [ "git" "docker" "npm" "python" "yarn" ];
            autosuggestions.enable    = true;
            syntaxHighlighting.enable = true;
          };

          services.docker.enable = true;
          users.users.aee.extraGroups = [ "docker" ];

          programs.flatpak.enable = true;

          environment.variables = {
            EDITOR = "zed";
          };
        };

        # ─────────────────────────────────────────────────────────────────────────
        # Global devShells
        # ─────────────────────────────────────────────────────────────────────────
        devShells.${system} = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ elixir erlang python3 nodejs yarn docker docker-compose ];
            shellHook  = ''
              export EDITOR=zed
              echo "🚀 Welcome to Aee's global dev shell!"
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
      }
    );
}
