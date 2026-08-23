# Gaming: GameMode, controllers, Steam (networking + Proton env) and gamescope.
# Adapted from https://codeberg.org/balint/nixos-configs/modules/gaming.nix.
# Enabled by default, disable per host with `mySystem.appGroups.gaming.enable = false`.
# Contributes a NixOS module to the `desktop` slot, gated on
# `mySystem.enableDesktop` like the rest of the desktop stack.
{ ... }: {
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
        remotePlay.openFirewall = true; # TCP+UDP 27036, UDP 27031-27035
        dedicatedServer.openFirewall = true; # TCP+UDP 27015
        localNetworkGameTransfers.openFirewall = true; # TCP 27040, UDP 27036
        package = pkgs.steam.override {
          extraEnv = {
            WINE_VK_VULKAN_ONLY = "1";
            PROTON_LOCAL_SHADER_CACHE = "1";
            MESA_SHADER_CACHE_MAX_SIZE = "8G";
            WINEDLLOVERRIDES = "dinput8,dxgi,dsound=n,b";
            PROTON_FSR4_UPGRADE = "1";
            # Quiet DXVK logging and force-close hung games.
            DXVK_LOG_LEVEL = "none";
            STEAM_FRAME_FORCE_CLOSE = "1";
          };
        };
      };
      # Gamescope session: fullscreen, realtime scheduling, adaptive sync,
      # Wayland exposure (-e) and the MangoHud overlay (--mangoapp; mangoapp
      # ships with the mangohud package). Nested gamescope costs iGPU time, so
      # drop -e if a specific game misbehaves.
      programs.gamescope = {
        enable = true;
        capSysNice = true;
        args = [ "-f" "--rt" "--adaptive-sync" "--backend sdl" "-e" "--mangoapp" ];
      };
      # Gamemode shell extension (shows GameMode state in the GNOME panel).
      # Appended via mkAfter so it follows the shared default extension list.
      mySystem.gnomeExtensions = lib.mkAfter [
        { uuid = "gamemode@charlieq0137gmail.com"; package = "gamemode-shell-extension"; }
      ];
      hardware.graphics.enable32Bit = true;
    };
  };
}
