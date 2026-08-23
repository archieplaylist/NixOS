# PipeWire + RTKit + low-latency gaming audio (desktop slot)
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkIf config.mySystem.enableDesktop {
      environment.systemPackages = [ pkgs.easyeffects ];

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        audio.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        # 48kHz / 128 quantum — only when gaming enabled
        extraConfig.pipewire."99-lowlatency.conf" =
          lib.optionalAttrs config.mySystem.appGroups.gaming.enable {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 128;
              "default.clock.min-quantum" = 64;
              "default.clock.max-quantum" = 512;
            };
          };
        wireplumber.extraConfig."99-lowlatency.conf" =
          lib.optionalAttrs config.mySystem.appGroups.gaming.enable {
            "monitor.rules" = [
              {
                matches = [{ "node.name" = "~alsa_output.*"; }];
                "actions.update-props" = {
                  "api.alsa.period-size" = 128;
                  "api.alsa.headroom" = 128;
                  "session.suspend-timeout-seconds" = 0;
                };
              }
            ];
          };
      };
    };
  };
}
