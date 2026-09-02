# Desktop slot: GNOME/GDM, Plasma/SDDM, plus shared X/Bluetooth/NetworkManager/Flatpak
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      (lib.mkIf config.mySystem.enableDesktop {
        services.xserver.enable = true;

        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = false;
        services.blueman.enable = config.mySystem.desktop != "plasma";

        networking.networkmanager.enable = true;

        services.flatpak.enable = true;
        services.flatpak.packages = config.mySystem.flatpakApps;
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "gnome") {
        services.displayManager.gdm.enable = true;
        services.gnome.gnome-keyring.enable = true;
        security.pam.services.gdm.enableGnomeKeyring = true;
        security.pam.services.gdm-password.enableGnomeKeyring = lib.mkDefault true;
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
          dconf-editor
        ] ++ (map (e: pkgs.gnomeExtensions.${e.package}) config.mySystem.gnomeExtensions);

        environment.gnome.excludePackages = with pkgs; [
          gnome-software
          epiphany
          gnome-maps
          gnome-weather
          gnome-contacts
          # GNOME Games
          swell-foop
          tali
          five-or-more
          four-in-a-row
          lightsoff
          gnome-chess
          gnome-sudoku
          gnome-mines
        ];
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "plasma") {
        services.displayManager.sddm.enable = true;
        services.desktopManager.plasma6.enable = true;

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde pkgs.xdg-desktop-portal-gtk ];
          config.common.default = "kde"; # ponytail: was missing → kde fallback to gtk caused 3-5s register wait
        };

        services.gnome.gnome-keyring.enable = true; # ponytail: reuse Login keyring from xfce/gnome, no relogin
        security.pam.services.sddm.enableGnomeKeyring = true;
        security.pam.services.sddm.kwallet.enable = true;

        environment.systemPackages = with pkgs; [
          kdePackages.dolphin
          kdePackages.konsole
          kdePackages.gwenview
          seahorse
        ];
      })
    ];
  };
}
