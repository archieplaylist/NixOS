{
  description = "NixOS desktop configuration for mario";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Packages not on the stable channel (e.g. discord) come from here via
    # the `pkgs.unstable` overlay below.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, sops-nix, nix-flatpak, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      # Build a NixOS configuration for hostname `name`.
      buildHost = name: lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/${name}.nix
          ./modules/system/options.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          {
            # `pkgs.unstable` — the nixpkgs-unstable package set, for apps that
            # aren't on the stable channel (discord). Unfree is allowed here so
            # discord resolves regardless of the stable config.
            nixpkgs.overlays = [
              (final: _prev: {
                unstable = import nixpkgs-unstable {
                  localSystem = { inherit system; };
                  config.allowUnfree = true;
                };
              })
            ];
          }
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
      };
    in
    {
      nixosConfigurations = {
        nixos-desktop = buildHost "nixos-desktop";
        nixos-laptop = buildHost "nixos-laptop";
        nixos-work = buildHost "nixos-work";
        vm-host = buildHost "vm-host";
      };

      # `nix flake check` builds every host config — catches module errors
      # before you rebuild on a real machine.
      checks.${system} =
        builtins.mapAttrs
        (_: cfg: cfg.config.system.build.toplevel)
        self.nixosConfigurations;

      # `nix develop` — formatter and Nix linters.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixpkgs-fmt
          deadnix
          statix
        ];
      };

      # `nix fmt` uses this.
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}