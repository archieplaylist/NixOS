{ config
, lib
, pkgs
, ...
}: {
  config = lib.mkIf config.mySystem.enableDesktop {
    # GNOME on Wayland via GDM.
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

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
      gnomeExtensions.appindicator
    ];

    # Gaming: Steam needs 32-bit multilib OpenGL. Enabled by default, disable
    # per host with `home-manager.users.mario.myApps.enable = false`.
    programs.steam = lib.mkIf config.home-manager.users.mario.myApps.enable {
      enable = true;
    };
    hardware.graphics.driSupport32Bit = lib.mkIf config.home-manager.users.mario.myApps.enable true;

    # Flatpak for third-party apps.
    services.flatpak.enable = true;
  };
}
