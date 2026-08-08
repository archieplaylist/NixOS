{
  description = "NixOS desktop configuration for mario";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    impermanence.url = "github:nix-community/impermanence";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, impermanence, nix-flatpak, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Build a NixOS configuration for hostname `name`.
      buildHost = name: lib.nixosSystem {
        inherit system;
modules = [
          ./hosts/${name}.nix
          ./modules/system/options.nix
          ./modules/system/impermanence.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              users.mario = import ./home/mario.nix;
              extraSpecialArgs = { inherit self inputs; };
            };
          }
        ];
        specialArgs = { inherit impermanence; };
      };
    in
    {
      nixosConfigurations = {
        nixos-desktop = buildHost "nixos-desktop";
        nixos-laptop = buildHost "nixos-laptop";
        nixos-work = buildHost "nixos-work";
        vm-host = buildHost "vm-host";
      };

      # `nix fmt` uses this.
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
