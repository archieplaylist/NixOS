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
      extraGSettingsOverrides = ''
        [org.gnome.shell]
        enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com', 'blur-my-shell@aunetx', 'caffeine@patapon.info', 'clipboard-indicator@tudmotu.com', 'CoverflowAltTab@palatis.blogspot.com', 'dash-to-dock@micxg.gmail.com', 'impatience@gfxmonk.net', 'just-perfection-desktop@just-perfection', 'drive-menu@gnome-shell-extensions.gcampax.github.com', 'tailscale-gnome-qs@tailscale-qs.github.io', 'user-theme@gnome-shell-extensions.gcampax.github.com']
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
      gnomeExtensions.appindicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.caffeine
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.coverflow-alt-tab
      gnomeExtensions.dash-to-dock
      gnomeExtensions.impatience
      gnomeExtensions.just-perfection
      gnomeExtensions.removable-drive-menu
      gnomeExtensions.user-theme
    ];

    # Gaming: Steam needs 32-bit multilib OpenGL. Enabled by default, disable
    # per host with `home-manager.users.mario.myApps.gaming.enable = false`.
    programs.steam = lib.mkIf config.home-manager.users.mario.myApps.gaming.enable {
      enable = true;
    };
    hardware.graphics.enable32Bit = lib.mkIf config.home-manager.users.mario.myApps.gaming.enable true;

    # Flatpak for third-party apps.
    services.flatpak.enable = true;
  };
}
