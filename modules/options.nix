# Top-level (flake-parts) options for the dendritic pattern.
#
# Lower-level modules (NixOS and home-manager) are stored as option values of
# this top-level configuration. Each slot below is an `attrsOf` of
# `lib.types.deferredModule`, so multiple top-level modules can merge their
# contribution into one slot, and a slot can be read back as a module to feed
# into a lower-level evaluation.
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
