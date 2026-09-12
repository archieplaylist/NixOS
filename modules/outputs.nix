# Flake wiring: nixosConfigurations + checks + devShell (flake-parts)
{ config, lib, inputs, ... }:
let
  system = "x86_64-linux";

  buildHost = name: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      config.nixos.hosts.${name}
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      {
        nixpkgs.overlays = [
          (_final: _prev: {
            unstable = import inputs.nixpkgs-unstable {
              localSystem = { inherit system; };
              config.allowUnfree = true;
            };
          })
          (_final: prev: {
            # ponytail: orchis from unstable for latest release (stable lags)
            orchis-theme = prev.unstable.orchis-theme;
          })
        ];
      }
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          users.mario = {
            imports = [
              config.home.modules.mario
              inputs.plasma-manager.homeModules.plasma-manager
            ];
          };
        };
      }
    ];
  };

  hosts = lib.mapAttrs (name: _: buildHost name) config.nixos.hosts;
in
{
  flake.nixosConfigurations = hosts;
  flake.checks.${system} = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) hosts;

  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        gnumake
        nixpkgs-fmt
        deadnix
        statix
        shellcheck
      ];
    };

    formatter = pkgs.nixpkgs-fmt;
  };
}
