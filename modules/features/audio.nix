# Audio: PipeWire with ALSA/Pulse/JACK, realtime scheduling (rtkit) and
# low-latency tuning for gaming. Contributes a NixOS module to the `desktop`
# slot, gated on `mySystem.enableDesktop` like the rest of the desktop stack.
{ ... }: {
  config.nixos.modules.desktop = { config, lib, ... }: {
    config = lib.mkIf config.mySystem.enableDesktop {
      # rtkit grants realtime scheduling; ALSA (incl. 32-bit) covers apps that
      # talk to ALSA directly instead of Pulse/JACK.
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        audio.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        # Low-latency audio for gaming (adapted from
        # https://github.com/Swam-web/customConfig/modules/audio.nix): fixed
        # 48 kHz clock, 128-frame quantum, and no ALSA device auto-suspend.
        # Applied only when the gaming group is on.
        extraConfig.pipewire."99-lowlatency.conf" = lib.mkIf config.mySystem.appGroups.gaming.enable {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 128;
            "default.clock.min-quantum" = 64;
            "default.clock.max-quantum" = 512;
          };
        };
        wireplumber.extraConfig."99-lowlatency.conf" = lib.mkIf config.mySystem.appGroups.gaming.enable {
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
