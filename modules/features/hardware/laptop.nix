# Laptop: power-profiles + lid suspend
_: {
  config.nixos.modules.laptop = { config, lib, ... }: {
    config = lib.mkIf config.mySystem.enableLaptop {
      services.power-profiles-daemon.enable = true;

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };
}
