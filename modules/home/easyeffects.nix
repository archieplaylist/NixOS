# EasyEffects presets — vendored from JackHack96/EasyEffects-Presets
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    xdg.configFile = lib.mkIf osConfig.mySystem.enableDesktop {
      "easyeffects/output".source = ./assets/easyeffects/output;
      "easyeffects/output".recursive = true;
      "easyeffects/irs".source = ./assets/easyeffects/irs;
      "easyeffects/irs".recursive = true;
    };

    systemd.user.services.easyeffects = lib.mkIf osConfig.mySystem.enableDesktop {
      Unit = {
        Description = "EasyEffects audio effects for PipeWire";
        After = [
          "graphical-session.target"
          "pipewire.service"
          "pipewire-pulse.service"
        ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
