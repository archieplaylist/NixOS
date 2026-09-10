# MangoHud — only when gaming group enabled
_: {
  config.home.modules.mario = { lib, osConfig, ... }: {
    home.file.".config/MangoHud/MangoHud.conf" = lib.mkIf osConfig.mySystem.appGroups.gaming.enable {
      text = ''
        gpu_stats
        cpu_stats
        fps
        frametime
        temperature
      '';
    };
  };
}
