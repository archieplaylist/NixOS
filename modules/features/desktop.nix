# Desktop environment slot: GNOME and KDE Plasma on Wayland, XFCE on X11, plus
# Bluetooth, NetworkManager and Flatpak (nix-flatpak). Display manager follows
# the DE: GNOME runs under GDM, Plasma under SDDM, XFCE under LightDM. Audio
# lives in audio.nix, gaming in gaming.nix (same slot, same enableDesktop
# gate). The DE is chosen per host via `mySystem.desktop` (see mySystem.nix).
# Contributes a NixOS module to the `desktop` slot, gated on
# `mySystem.enableDesktop`.
{ ... }: {
  config.nixos.modules.desktop = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      # Shared services: X server, Bluetooth, NetworkManager, Flatpak.
      (lib.mkIf config.mySystem.enableDesktop {
        services.xserver.enable = true;

        # Bluetooth. Radio stays off at boot (can be toggled on via the DE).
        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = false;
        services.blueman.enable = true;

        # Network management.
        networking.networkmanager.enable = true;

        # Flatpak for third-party apps. The daemon is enabled here; apps are
        # declared per host via `mySystem.flatpakApps` (nix-flatpak).
        services.flatpak.enable = true;
        services.flatpak.packages = config.mySystem.flatpakApps;
      })

      # GNOME stack. Display manager: GDM. Extensions: single source of truth
      # mySystem.gnomeExtensions (see mySystem.nix). The system-level GSettings
      # default and the per-user dconf value in modules/home/gnome.nix are both
      # derived from it.
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

      # KDE Plasma stack. Display manager: SDDM. The full session (kwin,
      # plasma-workspace, ...) comes from services.desktopManager.plasma6;
      # user-facing configuration is declared via plasma-manager in
      # modules/home/plasma.nix.
      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "plasma") {
        services.displayManager.sddm.enable = true;
        services.desktopManager.plasma6.enable = true;

        # Unlock KWallet automatically at the SDDM login prompt with the login
        # password (pam_kwallet). The wallet itself is set up in plasma.nix.
        security.pam.services.sddm.kwallet.enable = true;

        environment.systemPackages = with pkgs; [
          kdePackages.dolphin
          kdePackages.konsole
          kdePackages.gwenview
        ];
      })

      # XFCE stack. Display manager: LightDM. Unlike GNOME/Plasma (Wayland),
      # XFCE is X11-based, so it relies on the shared `services.xserver` block
      # above. The core session (xfwm4, xfdesktop, xfce4-panel, xfce4-session)
      # comes from services.xserver.desktopManager.xfce; user-facing config
      # (window theme, xsettings) is shipped as system-wide xfconf defaults
      # below. The panel is left at XFCE's stock default — custom panel XML
      # kept producing the "(null)" plugin dialog, so there is none. The extra
      # packages are the thin apps the stock session doesn't ship (mirroring
      # Plasma's dolphin/konsole).
      #
      # Note: LightDM still lives at the legacy `services.xserver.displayManager.*`
      # path — the display-manager refactor moved GDM/SDDM/lemurs to the new
      # `services.displayManager.*` namespace but kept LightDM where it was.
      (lib.mkIf (config.mySystem.enableDesktop && config.mySystem.desktop == "xfce") {
        services.xserver.displayManager.lightdm.enable = true;
        services.xserver.desktopManager.xfce.enable = true;

        # Extra apps the stock XFCE session doesn't ship (mirroring Plasma's
        # dolphin/konsole/gwenview). These used to live in the `xfce` package
        # set but were moved to top-level in this nixpkgs.
        environment.systemPackages = with pkgs; [
          xfce4-terminal
          xfce4-screenshooter
          xfce4-clipman-plugin
          xfce4-whiskermenu-plugin
          mousepad
        ];

        # Panel: XFCE's stock default. Every custom /etc/xdg xfce4-panel.xml we
        # shipped (Whisker menu, then plain stock plugins) STILL produced the
        # "Plugin '(null)' could not be loaded" dialog, so the panel config is
        # left entirely to xfce4-panel's own defaults — no custom XML at all.
        # (Note: XFCE 4.20's stock layout is a top panel plus a bottom dock —
        # two panels, but XFCE's own consistent config, so no error.)

        # Window manager (xfwm4): WhiteSur-Dark decorations to match the GTK
        # side, minimize/maximize/close on the right, and the built-in
        # compositor (no separate picom needed).
        environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="WhiteSur-Dark"/>
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="workspace_count" type="int" value="4"/>
    <property name="placement_mode" type="string" value="center"/>
    <property name="edge_resistance" type="int" value="10"/>
  </property>
</channel>
'';

        # xsettingsd: keep XFCE's GTK/icon/cursor choices in sync with the
        # home-manager gtk module (themes.nix) so panels, menus and dialogs all
        # render WhiteSur dark.
        environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="WhiteSur-dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="WhiteSur-cursors"/>
    <property name="CursorThemeSize" type="int" value="24"/>
  </property>
</channel>
'';

        # Self-healing: wipe ALL XFCE user state at every boot so the panel
        # and theme start fresh. There is no custom /etc/xdg panel config, so
        # xfce4-panel regenerates its own stock default each login — a clean
        # slate guarantees no stale user file (the actual cause of the
        # "Plugin '(null)' could not be loaded" dialog) is ever in effect.
        systemd.tmpfiles.rules = let
          home = config.users.users.mario.home;
        in [
          "R ${home}/.config/xfce4"
          "R ${home}/.config/xfconf"
          "R ${home}/.config/xfce4-session"
          "R ${home}/.local/share/xfce4"
          "r ${home}/.local/state/xfce-panel-setup-v2-done"
        ];
      })
    ];
  };
}
