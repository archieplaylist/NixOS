{
  description = "NixOS desktop configuration for mario";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Build a NixOS configuration for hostname `name`.
      buildHost = name: lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/${name}.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mario = import ./home/mario.nix;
              extraSpecialArgs = { inherit self inputs; };
            };
          }
        ];
      };
    in {
      nixosConfigurations = {
        nixos-desktop = buildHost "nixos-desktop";
        nixos-laptop = buildHost "nixos-laptop";
      };

      # `nix fmt` uses this.
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}