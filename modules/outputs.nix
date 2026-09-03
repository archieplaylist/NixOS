# Flake wiring: nixosConfigurations + checks + devShell (flake-parts)
{ config, lib, inputs, ... }:
let
  system = "x86_64-linux";

  # VirtualBox GuestAdditions fix for kernel 6.12+ (drm_fb_helper_alloc_info removed)
  patchVboxGuestAdditions = kernelPackages:
    kernelPackages.extend (_final: prev: {
      virtualboxGuestAdditions = prev.virtualboxGuestAdditions.overrideAttrs (old: {
        prePatch = (old.prePatch or "") + ''
          fb=$(find src -name vbox_fb.c 2>/dev/null | head -n1)
          if [ -n "$fb" ]; then
            sed -i 's@info = drm_fb_helper_alloc_info(helper);@info = helper->info;@' "$fb"
            sed -i 's@if (IS_ERR(info))@if (IS_ERR(info) || !info)@' "$fb"
          fi
        '';
      });
    });

  buildHost = name: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      config.nixos.hosts.${name}
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
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
            orchis-theme = prev.unstable.orchis-theme;
          })
          (_final: prev: {
            linuxPackages = patchVboxGuestAdditions prev.linuxPackages;
            linuxPackages_6_12 = patchVboxGuestAdditions (prev.linuxPackages_6_12 or prev.linuxPackages);
            linuxPackages_latest = patchVboxGuestAdditions prev.linuxPackages_latest;
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
      ];
    };

    formatter = pkgs.nixpkgs-fmt;
  };
}
