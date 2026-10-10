# EasyEffects presets — vendored from JackHack96/EasyEffects-Presets
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.enableDesktop && !osConfig.mySystem.isVm) {
      home.packages = [ pkgs.easyeffects ];

      xdg.configFile = {
        "easyeffects/output".source = ./assets/easyeffects/output;
        "easyeffects/output".recursive = true;
        "easyeffects/irs".source = ./assets/easyeffects/irs;
        "easyeffects/irs".recursive = true;
      };

      systemd.user.services.easyeffects = {
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
