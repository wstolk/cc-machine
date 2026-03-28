{
  description = "cc-machine: vibe coding machine setup for Ubuntu 24 LTS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Apply with: home-manager switch --flake .#<username>
      # or via install.sh which sets the username automatically
      homeConfigurations = {
        default = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            username = "user";
            homeDirectory = "/home/user";
          };
        };
      };

      # Allow `nix develop` for an interactive dev shell with all tools
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git
          curl
          wget
          nodejs_22
          go
          zellij
          zsh
        ];
        shellHook = ''
          echo "cc-machine dev shell ready"
        '';
      };
    };
}
