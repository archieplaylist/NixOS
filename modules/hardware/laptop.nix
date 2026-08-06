{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.mySystem.enableLaptop {
    # Power profiles for GNOME (balanced/power-saver/performance).
    services.power-profiles-daemon.enable = true;

    # Suspend on lid close, ignore when on external power.
    services.logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "ignore";
    };
  };
}