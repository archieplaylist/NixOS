# LightDM + XFCE system side (desktop slot, xfce only)
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: let
    orchis-latest = pkgs.orchis-theme.overrideAttrs (old: {
      version = "2026-07-07";
      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "Orchis-theme";
        rev = "2026-07-07";
        hash = "sha256-oX6+tPe0nGsl+OzFZCpbKvE00Z/xvP+NoHY7QZ9YAo0=";
      };
    });
  in {
    config = lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "xfce") {
      services.xserver.displayManager.lightdm.enable = true;

      # Greeter needs its own theme (runs before user session)
      services.xserver.displayManager.lightdm.greeters.gtk = {
        enable = true;
        theme = {
          package = orchis-latest;
          name = "Orchis-Dark";
        };
        iconTheme = {
          package = pkgs.tela-circle-icon-theme;
          name = "Tela-circle-dark";
        };
        cursorTheme = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
        };
      };

      services.gnome.gnome-keyring.enable = true;
      services.upower.enable = true;

      security.polkit.enable = true;
      environment.systemPackages = [ pkgs.polkit_gnome ];

      security.pam.services.lightdm.enableGnomeKeyring = true;

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome ];
        config.common.default = "gtk";
      };

      services.xserver.desktopManager.xfce.enable = true;
    };
  };
}
