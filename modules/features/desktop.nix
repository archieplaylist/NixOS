# GNOME desktop: GNOME on Wayland via GDM, Bluetooth, NetworkManager and
# Flatpak (nix-flatpak). Audio lives in audio.nix, gaming in gaming.nix (same
# slot, same enableDesktop gate). Contributes a NixOS module to the `desktop`
# slot, gated on `mySystem.enableDesktop`.
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkIf config.mySystem.enableDesktop {
      # GNOME on Wayland via GDM.
      services.xserver.enable = true;
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome = {
        enable = true;
        # Single source of truth for GNOME extensions: mySystem.gnomeExtensions
        # (see mySystem.nix). The system-level GSettings default and the
        # per-user dconf value in modules/home/gnome.nix are both derived from it.
        extraGSettingsOverrides = ''
          [org.gnome.shell]
          enabled-extensions=[${lib.concatMapStringsSep ", " (e: "'" + e.uuid + "'") config.mySystem.gnomeExtensions}]
        '';
        extraGSettingsOverridePackages = [
          pkgs.gsettings-desktop-schemas
          pkgs.gnome-shell
        ];
      };

      # Sound via PipeWire lives in modules/features/audio.nix; gaming
      # (Steam, GameMode, gamescope, controllers) in gaming.nix. Both share
      # this slot and gate, so desktop.nix stays focused on the GNOME stack.

      # Bluetooth. Radio stays off at boot (can be toggled on via GNOME).
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = false;
      services.blueman.enable = true;

      # Network management.
      networking.networkmanager.enable = true;

      environment.systemPackages = with pkgs; [
        gnome-tweaks
      ] ++ (map (e: pkgs.gnomeExtensions.${e.package}) config.mySystem.gnomeExtensions);

      # Flatpak for third-party apps. The daemon is enabled here; apps are
      # declared per host via `mySystem.flatpakApps` (nix-flatpak).
      services.flatpak.enable = true;
      services.flatpak.packages = config.mySystem.flatpakApps;
    };
  };
}
