# Plasma via plasma-manager — stock defaults, only when desktop == plasma
_: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    home.packages = lib.mkIf (osConfig.mySystem.desktop == "plasma") [
      pkgs.kitty
      # ponytail: packages only, no declarative config — set manually in System Settings
      pkgs.orchis-theme
      pkgs.tela-circle-icon-theme
      pkgs.bibata-cursors
      pkgs.nordic
    ];

    programs.plasma = lib.mkIf (osConfig.mySystem.desktop == "plasma") {
      enable = true;
      overrideConfig = false; # ponytail: true rewrites kwinrc/plasmarc every login → 3-5s plasmashell restart
    };
  };
}
