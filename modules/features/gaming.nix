# Gaming: GameMode, controllers, Steam (networking + Proton env) and gamescope.
# Adapted from https://codeberg.org/balint/nixos-configs/modules/gaming.nix.
# Enabled by default, disable per host with `mySystem.appGroups.gaming.enable = false`.
# Contributes a NixOS module to the `desktop` slot, gated on
# `mySystem.enableDesktop` like the rest of the desktop stack.
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkIf config.mySystem.enableDesktop {
      programs.gamemode = lib.mkIf config.mySystem.appGroups.gaming.enable {
        enable = true;
        settings = {
          general.renice = 20;
        };
      };
      # Controllers: Xbox (wired dongle + Bluetooth) and Steam hardware.
      hardware.xone = lib.mkIf config.mySystem.appGroups.gaming.enable { enable = true; };
      hardware.xpadneo = lib.mkIf config.mySystem.appGroups.gaming.enable { enable = true; };
      hardware.steam-hardware = lib.mkIf config.mySystem.appGroups.gaming.enable { enable = true; };
      programs.steam = lib.mkIf config.mySystem.appGroups.gaming.enable {
        enable = true;
        remotePlay.openFirewall = true; # TCP+UDP 27036, UDP 27031-27035
        dedicatedServer.openFirewall = true; # TCP+UDP 27015
        localNetworkGameTransfers.openFirewall = true; # TCP 27040, UDP 27036
        package = pkgs.steam.override {
          extraEnv = {
            WINE_VK_VULKAN_ONLY = "1";
            PROTON_LOCAL_SHADER_CACHE = "1";
            MESA_SHADER_CACHE_MAX_SIZE = "8G";
            PROTON_ADD_CONFIG = "fsr4rdna3";
            WINEDLLOVERRIDES = "dinput8,dxgi,dsound=n,b";
            PROTON_FSR4_UPGRADE = "1";
          };
        };
      };
      # Gamescope session: fullscreen, realtime scheduling, adaptive sync.
      programs.gamescope = lib.mkIf config.mySystem.appGroups.gaming.enable {
        enable = true;
        capSysNice = true;
        args = [
          "-f"
          "--rt"
          "--adaptive-sync"
          "--backend sdl"
        ];
      };
      # Gamemode shell extension (shows GameMode state in the GNOME panel).
      # Appended via mkAfter so it follows the shared default extension list.
      mySystem.gnomeExtensions = lib.mkIf config.mySystem.appGroups.gaming.enable (lib.mkAfter [
        { uuid = "gamemode@charlieq0137gmail.com"; package = "gamemode-shell-extension"; }
      ]);
      hardware.graphics.enable32Bit = lib.mkIf config.mySystem.appGroups.gaming.enable true;
    };
  };
}
