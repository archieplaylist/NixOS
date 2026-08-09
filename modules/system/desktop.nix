{ config
, lib
, pkgs
, ...
}: {
  config = lib.mkIf config.mySystem.enableDesktop {
    # GNOME on Wayland via GDM.
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome = {
      enable = true;
      # Single source of truth for GNOME extensions: mySystem.gnomeExtensions
      # (see options.nix). The system-level GSettings default and the per-user
      # dconf value in home/mario.nix are both derived from it.
      extraGSettingsOverrides = ''
        [org.gnome.shell]
        enabled-extensions=[${builtins.concatStringsSep ", " (map (e: "'" + e.uuid + "'") config.mySystem.gnomeExtensions)}]
      '';
      extraGSettingsOverridePackages = [
        pkgs.gsettings-desktop-schemas
        pkgs.gnome-shell
      ];
    };

    # Sound via PipeWire.
    services.pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Bluetooth.
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # Network management.
    networking.networkmanager.enable = true;

    environment.systemPackages = with pkgs; [
      gnome-tweaks
    ] ++ (map (e: pkgs.gnomeExtensions.${e.package}) config.mySystem.gnomeExtensions);

    # Gaming: Steam needs 32-bit multilib OpenGL. Enabled by default, disable
    # per host with `home-manager.users.mario.myApps.gaming.enable = false`.
    programs.steam = lib.mkIf config.home-manager.users.mario.myApps.gaming.enable {
      enable = true;
    };
    hardware.graphics.enable32Bit = lib.mkIf config.home-manager.users.mario.myApps.gaming.enable true;

    # Flatpak for third-party apps. The daemon is enabled here; apps are
    # declared per host via `mySystem.flatpakApps` (nix-flatpak).
    services.flatpak.enable = true;
    services.flatpak.packages = config.mySystem.flatpakApps;
  };
}