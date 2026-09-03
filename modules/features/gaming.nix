# Gaming: GameMode, Steam, gamescope, controllers (desktop slot, gaming group)
_: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkIf (config.mySystem.enableDesktop && config.mySystem.appGroups.gaming.enable) {
      programs.gamemode = {
        enable = true;
        settings = {
          general.renice = -5;
          custom = {
            start = "powerprofilesctl set performance";
            end = "powerprofilesctl set balanced";
          };
        };
      };
      boot.kernelParams = [ "split_lock_detect=off" ];
      boot.kernel.sysctl."vm.max_map_count" = 1048576;
      systemd.oomd.enable = true;
      services.thermald.enable = true;
      hardware.xone.enable = true;
      hardware.xpadneo.enable = true;
      hardware.steam-hardware.enable = true;
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        package = pkgs.steam.override {
          extraEnv = {
            WINE_VK_VULKAN_ONLY = "1";
            PROTON_LOCAL_SHADER_CACHE = "1";
            MESA_SHADER_CACHE_MAX_SIZE = "8G";
            WINEDLLOVERRIDES = "dinput8,dxgi,dsound=n,b";
            PROTON_FSR4_UPGRADE = "1";
            DXVK_LOG_LEVEL = "none";
            STEAM_FRAME_FORCE_CLOSE = "1";
          };
        };
      };
      programs.gamescope = {
        enable = true;
        capSysNice = true;
        args = [ "-f" "--rt" "--adaptive-sync" "--backend" "sdl" "-e" "--mangoapp" ];
      };
      mySystem.gnomeExtensions = lib.mkAfter [
        { uuid = "gamemode@charlieq0137gmail.com"; package = "gamemode-shell-extension"; }
      ];
      hardware.graphics.enable32Bit = true;
    };
  };
}
