# LightDM / XFCE system slot (split out of the old modules/features/xfce.nix).
# XFCE is X11-based, so it relies on the shared `services.xserver` block from
# the `desktop` slot. This file owns the system side of the XFCE stack: the
# LightDM display manager (now Stylix-themed) and enabling
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

      # LightDM GTK greeter theming is now owned by Stylix
      # (stylix.targets.lightdm.enable in modules/features/stylix.nix).
      # The greeter is a pre-login process — it never sees home-manager GTK —
      # so Stylix themes it at the NixOS level along with the shared palette.

      # The XFCE session itself must be enabled system-wide (it provides
      # xfce4-session, xfwm4, xfdesktop, xfce4-panel from nixpkgs). User-facing
      # config is managed per-user in modules/home/xfce.nix.
      services.xserver.desktopManager.xfce.enable = true;
    };
  };
}