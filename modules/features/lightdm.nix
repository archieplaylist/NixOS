# LightDM / XFCE system slot (split out of the old modules/features/xfce.nix).
# XFCE is X11-based, so it relies on the shared `services.xserver` block from
# the `desktop` slot. This file owns the system side of the XFCE stack: the
# LightDM display manager (Nordic-themed GTK greeter) and enabling
# the XFCE session itself (services.xserver.desktopManager.xfce). All
# user-facing XFCE configuration (panel, xfwm4, xsettings, shortcuts, extra
# apps) is managed per-user by home-manager in modules/home/xfce.nix —
# mirroring how Plasma's user config lives in modules/home/plasma.nix.
#
# Note: LightDM still lives at the legacy `services.xserver.displayManager.*`
# path — the display-manager refactor moved GDM/SDDM/lemurs to the new
# `services.displayManager.*` namespace but kept LightDM where it was.
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "xfce") {
      services.xserver.displayManager.lightdm.enable = true;

      # Theme the LightDM GTK greeter (the login screen). The greeter runs as
      # its own process before any user session, so it never sees the
      # home-manager GTK settings or the XFCE xsettings.xml — it needs its
      # own theme/icon/cursor config here.
      services.xserver.displayManager.lightdm.greeters.gtk = {
        enable = true;
        theme = {
          package = pkgs.nordic;
          name = "Nordic";
        };
        iconTheme = {
          package = pkgs.papirus-icon-theme;
          name = "Papirus-Dark";
        };
        cursorTheme = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
        };
      };

      services.gnome.gnome-keyring.enable = true;

      security.pam.services.lightdm.enableGnomeKeyring = true;

      # The XFCE session itself must be enabled system-wide (it provides
      # xfce4-session, xfwm4, xfdesktop, xfce4-panel from nixpkgs). User-facing
      # config is managed per-user in modules/home/xfce.nix.
      services.xserver.desktopManager.xfce.enable = true;
    };
  };
}