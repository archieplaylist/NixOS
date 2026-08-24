# Desktop slot: GNOME/GDM, Plasma/SDDM, plus shared X/Bluetooth/NetworkManager/Flatpak
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      (lib.mkIf config.mySystem.enableDesktop {
        services.xserver.enable = true;

        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = false;
        services.blueman.enable = config.mySystem.desktop != "plasma" && config.mySystem.desktop != "pantheon";

        networking.networkmanager.enable = true;

        services.flatpak.enable = true;
        services.flatpak.packages = config.mySystem.flatpakApps;
      })

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

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "plasma") {
        services.displayManager.sddm.enable = true;
        services.desktopManager.plasma6.enable = true;
        security.pam.services.sddm.kwallet.enable = true;

        environment.systemPackages = with pkgs; [
          kdePackages.dolphin
          kdePackages.konsole
          kdePackages.gwenview
        ];
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "pantheon") {
        # ponytail: minimal pantheon — module warns without lightdm, so enable it
        services.desktopManager.pantheon.enable = true;
        services.xserver.displayManager.lightdm.enable = true;
        services.pantheon.apps.enable = true;
        environment.systemPackages = with pkgs; [ pantheon-tweaks ];
      })
    ];
  };
}
