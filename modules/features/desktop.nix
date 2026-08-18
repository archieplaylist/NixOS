# Desktop environment slot: GNOME and KDE Plasma on Wayland, XFCE on X11, plus
# Bluetooth, NetworkManager and Flatpak (nix-flatpak). Display manager follows
# the DE: GNOME runs under GDM, Plasma under SDDM, XFCE under LightDM. Audio
# lives in audio.nix, gaming in gaming.nix (same slot, same enableDesktop
# gate). The DE is chosen per host via `mySystem.desktop` (see mySystem.nix).
# Contributes a NixOS module to the `desktop` slot, gated on
# `mySystem.enableDesktop`.
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      # Shared services: X server, Bluetooth, NetworkManager, Flatpak.
      (lib.mkIf config.mySystem.enableDesktop {
        services.xserver.enable = true;

        # Bluetooth. Radio stays off at boot (can be toggled on via the DE).
        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = false;
        services.blueman.enable = true;

        # Network management.
        networking.networkmanager.enable = true;

        # Flatpak for third-party apps. The daemon is enabled here; apps are
        # declared per host via `mySystem.flatpakApps` (nix-flatpak).
        services.flatpak.enable = true;
        services.flatpak.packages = config.mySystem.flatpakApps;
      })

      # GNOME stack. Display manager: GDM. Extensions: single source of truth
      # mySystem.gnomeExtensions (see mySystem.nix). The system-level GSettings
      # default and the per-user dconf value in modules/home/gnome.nix are both
      # derived from it.
      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "gnome") {
        services.displayManager.gdm.enable = true;
        services.desktopManager.gnome = {
          enable = true;
          extraGSettingsOverrides = ''
            [org.gnome.shell]
            enabled-extensions=[${lib.concatMapStringsSep ", " (e: "'" + e.uuid + "'") config.mySystem.gnomeExtensions}]
          '';
          extraGSettingsOverridePackages = [
            pkgs.gsettings-desktop-schemas
            pkgs.gnome-shell
          ];
        };

        environment.systemPackages = with pkgs; [
          gnome-tweaks
        ] ++ (map (e: pkgs.gnomeExtensions.${e.package}) config.mySystem.gnomeExtensions);
      })

      # KDE Plasma stack. Display manager: SDDM. The full session (kwin,
      # plasma-workspace, ...) comes from services.desktopManager.plasma6;
      # user-facing configuration is declared via plasma-manager in
      # modules/home/plasma.nix.
      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "plasma") {
        services.displayManager.sddm.enable = true;
        services.desktopManager.plasma6.enable = true;

        # Unlock KWallet automatically at the SDDM login prompt with the login
        # password (pam_kwallet). The wallet itself is set up in plasma.nix.
        security.pam.services.sddm.kwallet.enable = true;

        environment.systemPackages = with pkgs; [
          kdePackages.dolphin
          kdePackages.konsole
          kdePackages.gwenview
        ];
      })

      # XFCE stack. Display manager: LightDM. Unlike GNOME/Plasma (Wayland),
      # XFCE is X11-based, so it relies on the shared `services.xserver` block
      # above. The core session (xfwm4, xfdesktop, xfce4-panel, xfce4-session)
      # comes from services.xserver.desktopManager.xfce; user-facing config
      # (window theme, xsettings, panel) is declared via xfconf XML files in
      # modules/home/xfce.nix. The extra packages below are the thin apps the
      # stock session doesn't ship (mirroring Plasma's dolphin/konsole/gwenview).
      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "xfce") {
        services.displayManager.lightdm.enable = true;
        services.xserver.desktopManager.xfce.enable = true;

        environment.systemPackages = with pkgs; [
          xfce.xfce4-terminal
          xfce.xfce4-screenshooter
          xfce.xfce4-clipman-plugin
          xfce.xfce4-whiskermenu-plugin
          xfce.mousepad
        ];
      })
    ];
  };
}
