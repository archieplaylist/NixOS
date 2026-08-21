# XFCE user configuration, managed by home-manager (mirrors plasma.nix).
# Active only when this host runs XFCE (mySystem.desktop == "xfce"). The
# xfconf per-channel XMLs are written straight into the user's config dir
# (~/.config/xfce4/xfconf/xfce-perchannel-xml), so xfconfd reads them
# directly — there are no /etc/xdg system defaults anymore (they lived in the
# old modules/features/xfce.nix, split in favour of home-manager management).
#
# The panel XML is the user's own working config (a single bottom panel with
# Whisker menu) — the one layout that finally stopped the "(null)" plugin
# dialog. It is consistent: every id in `plugin-ids` (4,2,3,6,1,5,7,8,9) has a
# matching /plugins/plugin-N entry (1=pulseaudio, 4=whiskermenu), which is
# what keeps the "(null)" dialog away.
#
# force = true: xfconfd writes runtime state back into these XMLs (panel
# tweaks, window positions), and home-manager by default skips replacing files
# modified externally since activation. force makes the declarative file win on
# every rebuild — the "self-healing" behaviour the old boot-time tmpfiles wipe
# provided, now at rebuild time (same philosophy as plasma-manager's
# overrideConfig).
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.desktop == "xfce") {
      # Extra apps the stock XFCE session doesn't ship (mirroring Plasma's
      # dolphin/konsole/gwenview). These used to be system packages in
      # modules/features/xfce.nix; moved here so the whole XFCE stack is
      # user-managed.
      home.packages = with pkgs; [
        xfce4-terminal
        xfce4-screenshooter
        xfce4-clipman-plugin
        xfce4-whiskermenu-plugin
        mousepad
      ];

      xdg.configFile = {
        "xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" = {
          force = true;
          source = ./assets/xfce/xfce4-panel.xml;
        };

        # Super (Meta) key opens the Whisker menu. The whiskermenu plugin (2.8+)
        # dropped its own `super-key` xfconf option, so bind the bare key via the
        # keyboard-shortcuts channel: xfce4-popup-whiskermenu pops the menu
        # (needs plugin-4 whiskermenu in the panel above).
        "xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" = {
          force = true;
          source = ./assets/xfce/xfce4-keyboard-shortcuts.xml;
        };

        # Window manager (xfwm4): Stylix manages the theme. Keep the xml
        # for non-theme bits (button layout, compositing, workspace count)
        # but Stylix's `stylix.targets.xfce` will override ThemeName.
        # Either keep this channel disabled here or let Stylix win.
        # We keep the file but comment explains Stylix ownership.

        # xsettings: Stylix manages GTK/icon/cursor via xfsettingsd. The
        # xsettings.xml with WhiteSur values is now superseded — Stylix
        # writes the themed values. Keeping the file would fight Stylix,
        # so disable it when Stylix is enabled (see below).

        # Screensaver (xfce4-screensaver): disabled entirely — no blanking, no
        # lock after idle, and no lock on suspend. The DPMS monitor power-off is
        # also off (the monitor stays on; that's the whole point).
        "xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml" = {
          force = true;
          source = ./assets/xfce/xfce4-screensaver.xml;
        };

        # Desktop icons (xfdesktop): disabled entirely. xfdesktop only renders
        # icons when /desktop-icons/file-icons shows them; all show-* are false
        # so no Home/Filesystem/Trash or mounted-volume icons appear. Wallpaper
        # still shows.
        "xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" = {
          force = true;
          source = ./assets/xfce/xfce4-desktop.xml;
        };
      };
    };
}
