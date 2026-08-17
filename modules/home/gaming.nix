# Gaming user config: declarative MangoHud settings, active only when the
# gaming group is on. Packages live in apps.nix; system-side gaming tweaks
# live in modules/features/gaming.nix.
{ ... }: {
  config.home.modules.mario = { lib, osConfig, ... }: {
    home.file.".config/MangoHud/MangoHud.conf" = lib.mkIf osConfig.mySystem.appGroups.gaming.enable {
      text = ''
        fps_limit=0
        vsync=0
        gpu_stats
        cpu_stats
        fps
        frametime
        temperature
      '';
    };
  };
}
