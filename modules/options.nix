# Dendritic slots: nixos.modules / nixos.hosts / home.modules (deferredModule)
{ lib, ... }: {
  options.nixos.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.nullOr lib.types.deferredModule);
    default = { };
    description = "NixOS feature modules, merged by slot name (e.g. base, desktop, intel).";
  };

  options.nixos.hosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.nullOr lib.types.deferredModule);
    default = { };
    description = "Per-machine NixOS modules. Each key is a flake output name.";
  };

  options.home.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.nullOr lib.types.deferredModule);
    default = { };
    description = "home-manager feature modules, merged by user name (e.g. mario).";
  };
}
