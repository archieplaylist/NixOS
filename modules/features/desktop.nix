# Desktop slot: shared X/Bluetooth/NetworkManager/Flatpak + PipeWire,
# GNOME/GDM, Cinnamon/LightDM, Plasma/SDDM. Sections merged, behavior unchanged.
_: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      (lib.mkIf config.mySystem.enableDesktop {
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          audio.enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };

        services = {
          blueman.enable = config.mySystem.desktop != "plasma";
          # ppd owns the CPU governor on desktop hosts; vm left to its host defaults
          power-profiles-daemon.enable = !config.mySystem.isVm;
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

        # nautilus trash + mtp/smb + sidebar mounts outside GNOME need these
        services.gvfs.enable = true;
        services.udisks2.enable = true;
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "gnome") {
        services = {
          xserver.enable = true;
          displayManager.gdm.enable = true;
          gnome.gnome-keyring.enable = true;
          desktopManager.gnome = {
            enable = true;
            # system-wide override so the GDM login shell can load extensions
            # pre-login; the user session list is set in home/desktops/gnome.nix
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
          networkmanagerapplet # nm-connection-editor: GNOME Settings has no add-ethernet UI
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

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "cinnamon") {
        services = {
          xserver.enable = true;
          xserver.displayManager.lightdm.enable = true;
          xserver.desktopManager.cinnamon.enable = true;
          gnome.gnome-keyring.enable = true;
          upower.enable = true;
        };

        security.pam.services.lightdm.enableGnomeKeyring = true;

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
          config.common.default = "gtk";
        };
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "plasma") {
        services = {
          displayManager.sddm = {
            enable = true;
            wayland.enable = true;
          };
          desktopManager.plasma6.enable = true;
          gnome.gnome-keyring.enable = true;
        };

        # shared Login keyring unlocks at SDDM login, same as the other DEs
        security.pam.services.sddm.enableGnomeKeyring = true;

        environment.systemPackages = with pkgs.kdePackages; [
          plasma-browser-integration
        ];

        environment.plasma6.excludePackages = with pkgs.kdePackages; [
          discover
        ];
      })

    ];
  };
}
