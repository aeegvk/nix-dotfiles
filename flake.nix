{
  description = "Aee’s unified Dev flake: Home-Manager + DevShells";

  inputs = {
    # Pin nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Pin Home-Manager and wire it to the same nixpkgs
    home-manager = {
      url                = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # declarative Flatpak support
    nixflatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixflatpak, ... }:
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
          nixflatpak.homeManagerModules.nix-flatpak

          ({ config, pkgs, lib, ... }: {
            # Basic user info
            home.username      = "aee";
            home.homeDirectory = "/home/aee";
            home.stateVersion  = "25.05";

            # enable Flatpak & install OBS Studio as Flatpak :contentReference[oaicite:1]{index=1}
            services.flatpak.enable   = true;
            services.flatpak.packages = [
              "com.obsproject.Studio"
              "org.inkscape.Inkscape"
              "org.gimp.GIMP"
              "io.dbeaver.DBeaverCommunity"
            ];

            # Packages & GUI Apps
            home.packages = with pkgs; [
              noto-fonts
              google-chrome brave unstable.zed-editor
              sublime-merge flatpak git neovim
              fastfetch docker docker-compose
              elixir python3 nodejs yarn fish
            ];

            # Drop helper scripts into ~/bin
            home.file = {
              "bin/install-nix.sh" = {
                text       = builtins.readFile ./install-nix.sh;
                executable = true;
              };
            };

            # Update XDG_DATA_DIRS to include user's nix-profile share
            home.sessionVariables = {
              XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
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
