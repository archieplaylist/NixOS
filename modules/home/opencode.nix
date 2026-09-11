# opencode — gated on mySystem.appGroups.ai.enable (all hosts except vm)
{ inputs, ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    {
      config = lib.mkIf osConfig.mySystem.appGroups.ai.enable {
        home.packages = [
          pkgs.unstable.opencode
        ];

        # ponytail: same upstream skill dirs as pi.nix, versioned in flake.lock —
        # update with `nix flake update ponytail caveman`, no hand-rolled copies to drift.
        # Per-dir entries only — never manage ~/.config/opencode/ as a whole,
        # or imperative `plugin` installs in opencode.json get wiped on rebuild.
        xdg.configFile."opencode/skills/ponytail".source = "${inputs.ponytail}/skills/ponytail";
        xdg.configFile."opencode/skills/caveman".source = "${inputs.caveman}/skills/caveman";
      };
    };
}
