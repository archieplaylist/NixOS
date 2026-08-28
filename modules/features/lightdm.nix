# LightDM + XFCE system side (desktop slot, xfce only)
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "xfce") {
      services.xserver.displayManager.lightdm.enable = true;

      # Greeter needs its own theme (runs before user session)
      services.xserver.displayManager.lightdm.greeters.gtk = {
        enable = true;
        theme = {
          package = pkgs.qogir-theme;
          name = "Qogir-Dark";
        };
        iconTheme = {
          package = pkgs.qogir-icon-theme;
          name = "Qogir-Dark";
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
