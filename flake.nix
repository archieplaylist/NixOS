{
  description = "NixOS desktop configuration for mario";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # ponytail: discord needs fresher version than stable — reuse unstable overlay (keep nixpkgs input)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # plasma-manager — only needed when mySystem.desktop == "plasma"
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      # dendritic: every .nix under ./modules is a top-level flake-parts module
      importTree = dir:
        let
          entries = builtins.readDir dir;
          names = builtins.attrNames entries;
          files = builtins.filter (n: entries.${n} == "regular" && lib.hasSuffix ".nix" n) names;
          dirs = builtins.filter (n: entries.${n} == "directory") names;
        in
        (map (f: dir + "/${f}") files)
        ++ (builtins.concatMap (d: importTree (dir + "/${d}")) dirs);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = importTree ./modules;
    };
}
