# Flake output wiring (flake-parts machinery, not a feature module).
#
# Reads the top-level config's slot options and emits:
#   - nixosConfigurations.<host>  for every entry in nixos.hosts
#   - checks."x86_64-linux".<host> (toplevel derivations, so `nix flake check`
#     builds every host config)
#   - perSystem devShells (nix develop) and formatter (nix fmt)
{ config, lib, inputs, ... }:
let
  system = "x86_64-linux";

  # Build a NixOS configuration for a host whose NixOS module is stored in the
  # top-level slot `config.nixos.hosts.${name}`.
  buildHost = name: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      config.nixos.hosts.${name}
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.nix-flatpak.nixosModules.nix-flatpak
      {
        # `pkgs.unstable` — the nixpkgs-unstable package set, for apps that
        # aren't on the stable channel (discord). Unfree is allowed here so
        # discord resolves regardless of the stable config.
        nixpkgs.overlays = [
          (_final: _prev: {
            unstable = import inputs.nixpkgs-unstable {
              localSystem = { inherit system; };
              config.allowUnfree = true;
            };
          })
        ];
      }
      {
        # Home-manager is configured inside the flake, so `nixos-rebuild switch`
        # updates it too — no separate `home-manager switch` needed.
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          users.mario = config.home.modules.mario;
        };
      }
    ];
  };

  hosts = lib.mapAttrs (name: _: buildHost name) config.nixos.hosts;
in
{
  flake.nixosConfigurations = hosts;

  # `nix flake check` builds every host config — catches module errors before
  # you rebuild on a real machine.
  flake.checks.${system} = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) hosts;

  perSystem = { pkgs, ... }: {
    # `nix develop` — formatter and Nix linters.
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        nixpkgs-fmt
        deadnix
        statix
      ];
    };

    # `nix fmt` uses this.
    formatter = pkgs.nixpkgs-fmt;
  };
}
