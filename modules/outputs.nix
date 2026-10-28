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
      inputs.ayu-theme.nixosModules.default
      # home content resolved here (flake level); wired to
      # home-manager.users.<mySystem.username> in base.nix (NixOS level)
      { _module.args.homeModules = config.home.modules.primary; }
      {
        nixpkgs.overlays = [
          # ayu-theme: GTK2/3/4 + gnome-shell + xfwm4 theme (pkgs.ayu-theme)
          inputs.ayu-theme.overlays.default
          (_final: _prev: {
            unstable = import inputs.nixpkgs-unstable {
              localSystem = { inherit system; };
              config.allowUnfree = true;
            };
          })
          (_final: prev: {
            # opencode - npm platform binary, ahead of nixpkgs' v1
            opencode = prev.callPackage ../packages/opencode.nix { };
            # fetch - animated 3D fetch tool (areofyl/fetch)
            fetch = prev.callPackage ../packages/fetch.nix { };
            mactahoe-icons = prev.callPackage ../packages/mactahoe-icons.nix { };
            gnomeExtensions = prev.gnomeExtensions // {
              simple-taskbar = prev.callPackage ../packages/simple-taskbar.nix { };
            };
          })
        ];
      }
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          # stale .hm-backup files must not abort the whole switch
          overwriteBackup = true;
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
    # flake outputs so `nix-update --flake <name>` can bump version+hash
    packages.opencode = pkgs.callPackage ../packages/opencode.nix { };
    packages.fetch = pkgs.callPackage ../packages/fetch.nix { };
    packages.mactahoe-icons = pkgs.callPackage ../packages/mactahoe-icons.nix { };
    packages.simple-taskbar = pkgs.callPackage ../packages/simple-taskbar.nix { };

    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        gnumake
        nixpkgs-fmt
        deadnix
        statix
        shellcheck
        nix-update
      ];
    };

    formatter = pkgs.nixpkgs-fmt;
  };
}
