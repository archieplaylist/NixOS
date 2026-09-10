# Plasma via plasma-manager — stock defaults, only when desktop == plasma
_: {
  config.home.modules.mario = { lib, osConfig, ... }: {
    programs.plasma = lib.mkIf (osConfig.mySystem.desktop == "plasma") {
      enable = true;
      overrideConfig = false; # ponytail: true rewrites kwinrc/plasmarc every login → 3-5s plasmashell restart
    };
  };
}
