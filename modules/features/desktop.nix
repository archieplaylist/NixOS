# Desktop slot: shared X/Bluetooth/NetworkManager/Flatpak + PipeWire,
# GNOME/GDM, Niri/Ly, XFCE/LightDM, Plasma/SDDM. Sections merged, behavior unchanged.
_: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      (lib.mkIf config.mySystem.enableDesktop {
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

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "niri") {
        programs.niri = {
          enable = true;
          package = pkgs.unstable.niri; # unstable tracks niri releases, stable lags
        };
        # noctalia v5 from nixpkgs-unstable (same overlay as discord/vscode, no new flake input)
        # recommendedServices equiv: NM/BT already on above, upower + power-profiles here
        services.upower.enable = true;
        services.displayManager.ly.enable = true;
        services.gnome.gnome-keyring.enable = true;
        # gnome-keyring owns ssh here; gcr would run a second ssh agent
        services.gnome.gcr-ssh-agent.enable = false;
        programs.seahorse.enable = true; # Login-keyring GUI + ssh-askpass
        security.polkit.enable = true;
        security.pam.services.ly.enableGnomeKeyring = true;

        # satellite on PATH = niri auto-spawns it for X11 clients, no config block needed
        environment.systemPackages = with pkgs; [
          unstable.xwayland-satellite
          unstable.noctalia # v5 from unstable, stable 26.05 lacks it
          alacritty # themed by noctalia builtin template (see desktops.nix)
          foot
          polkit_gnome # niri ships no auth agent; keyring/polkit prompts need one
        ];

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome ];
          config.niri."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
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
      })

      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "xfce") {
        services = {
          xserver.enable = true;
          xserver.displayManager.lightdm.enable = true;

          # Greeter stock defaults (no custom theme)
          xserver.displayManager.lightdm.greeters.gtk.enable = true;

          gnome.gnome-keyring.enable = true;
          upower.enable = true;
          xserver.desktopManager.xfce.enable = true;
        };

        security.polkit.enable = true;
        environment.systemPackages = [ pkgs.polkit_gnome ];

        security.pam.services.lightdm.enableGnomeKeyring = true;

        # Declarative Xfce defaults: xfconfd merges these system channel files
        # with the user's ~/.config/xfce4/xfconf/xfce-perchannel-xml/ (user wins),
        # so a wiped home dir still boots into our theme/layout instead of stock.
        # The home-manager seed in desktops/xfce.nix copies the same files into
        # the user dir when missing (belt & braces); user GUI edits always win.
        environment.etc = {
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".source = ../home/assets/xfce/xsettings.xml;
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".source = ../home/assets/xfce/xfwm4.xml;
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".source = ../home/assets/xfce/xfce4-desktop.xml;
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml".source = ../home/assets/xfce/xfce4-session.xml;
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml".source = ../home/assets/xfce/xfce4-power-manager.xml;
          "xdg/xfce4/xfconf/xfce-perchannel-xml/keyboards.xml".source = ../home/assets/xfce/keyboards.xml;
          "xdg/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".source = ../home/assets/xfce/thunar.xml;
          # first-run panel layout (migrate helper reads the first match;
          # /etc/xdg precedes the panel package's own store fallback)
          "xdg/xfce4/panel/default.xml".source = ../home/assets/xfce/panel-default.xml;
        };

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome ];
          config.common.default = "gtk";
        };
      })
    ];
  };
}
