# Desktop slot: GNOME/GDM, Plasma/SDDM, plus shared X/Bluetooth/NetworkManager/Flatpak
_: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      (lib.mkIf config.mySystem.enableDesktop {
        services = {
          xserver.enable = true;
          blueman.enable = config.mySystem.desktop != "plasma";
          flatpak = {
            enable = true;
            packages = config.mySystem.flatpakApps;
          };
        };

        hardware.bluetooth = {
          enable = true;
          powerOnBoot = false;
        };

        networking.networkmanager.enable = true;
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "gnome") {
        services = {
          displayManager.gdm.enable = true;
          gnome.gnome-keyring.enable = true;
          desktopManager.gnome = {
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
        };
        security.pam.services.gdm.enableGnomeKeyring = true;
        security.pam.services.gdm-password.enableGnomeKeyring = lib.mkDefault true;

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
        services = {
          displayManager.sddm.enable = true;
          desktopManager.plasma6.enable = true;
          gnome.gnome-keyring.enable = true; # ponytail: reuse Login keyring from xfce/gnome, no relogin
        };

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde pkgs.xdg-desktop-portal-gtk ];
          config.common.default = "kde"; # ponytail: was missing → kde fallback to gtk caused 3-5s register wait
        };

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
