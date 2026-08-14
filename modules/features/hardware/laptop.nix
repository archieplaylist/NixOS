# Laptop power management: power profiles for GNOME and lid handling.
# Contributes a NixOS module to the `laptop` slot, gated on
# `mySystem.enableLaptop`.
{ ... }: {
  config.nixos.modules.laptop = { config, lib, ... }: {
    config = lib.mkIf config.mySystem.enableLaptop {
      # Power profiles for GNOME (balanced/power-saver/performance).
      services.power-profiles-daemon.enable = true;

      # Suspend on lid close, ignore when on external power.
      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };
}
