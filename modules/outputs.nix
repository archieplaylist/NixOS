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

  # VirtualBox GuestAdditions 7.2.14 predate the kernel's fbdev emulation
  # change that removed drm_fb_helper_alloc_info (present in 6.12+), so its
  # vboxvideo driver fails to build against modern kernels. Patch vbox_fb.c to
  # use the new API where the fb_info lives on the helper, mirroring upstream
  # VirtualBox. The NULL guard fails fbdev setup cleanly instead of crashing.
  patchVboxGuestAdditions = kernelPackages:
    kernelPackages.extend (_final: prev: {
      virtualboxGuestAdditions = prev.virtualboxGuestAdditions.overrideAttrs (old: {
        prePatch = (old.prePatch or "") + ''
          sed -i 's@info = drm_fb_helper_alloc_info(helper);@info = helper->info;@' \
            src/vboxguest-7.2.14_NixOS/vboxvideo/vbox_fb.c
          sed -i 's@if (IS_ERR(info))@if (IS_ERR(info) || !info)@' \
            src/vboxguest-7.2.14_NixOS/vboxvideo/vbox_fb.c
        '';
      });
    });

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
          # Fix VirtualBox GuestAdditions 7.2.14 for modern kernels (see
          # patchVboxGuestAdditions above). Applied to the default and pinned
          # kernel sets so vm-host can use the default kernel.
          (final: prev: {
            linuxPackages = patchVboxGuestAdditions prev.linuxPackages;
            linuxPackages_6_12 = patchVboxGuestAdditions (prev.linuxPackages_6_12 or prev.linuxPackages);
            linuxPackages_latest = patchVboxGuestAdditions prev.linuxPackages_latest;
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
