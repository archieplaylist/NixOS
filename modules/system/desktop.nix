{ config
, lib
, pkgs
, ...
}: {
  config = lib.mkIf config.mySystem.enableDesktop {
    # GNOME on Wayland via GDM.
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
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
      gnomeExtensions.appindicator
    ];

    # Flatpak for browser and third-party apps.
    services.flatpak.enable = true;
  };
}
