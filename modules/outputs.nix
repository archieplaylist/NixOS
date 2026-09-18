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
      # home content resolved here (flake level); wired to
      # home-manager.users.<mySystem.username> in base.nix (NixOS level)
      { _module.args.homeModules = config.home.modules.primary; }
      {
        nixpkgs.overlays = [
          (_final: _prev: {
            unstable = import inputs.nixpkgs-unstable {
              localSystem = { inherit system; };
              config.allowUnfree = true;
            };
          })
          (_final: prev: {
            # orchis from unstable for latest release (stable lags)
            orchis-theme = prev.unstable.orchis-theme;
            # opencode - custom package for v2 beta
            opencode = prev.callPackage ../packages/opencode.nix { };
          })
        ];
      }
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
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
