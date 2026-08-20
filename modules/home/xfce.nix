# XFCE user configuration, managed by home-manager (mirrors plasma.nix).
# Active only when this host runs XFCE (mySystem.desktop == "xfce"). The
# xfconf per-channel XMLs are written straight into the user's config dir
# (~/.config/xfce4/xfconf/xfce-perchannel-xml), so xfconfd reads them
# directly — there are no /etc/xdg system defaults anymore (they lived in the
# old modules/features/xfce.nix, split in favour of home-manager management).
#
# The panel XML is the user's own working config (a single bottom panel with
# Whisker menu) — the one layout that finally stopped the "(null)" plugin
# dialog. It is consistent: every id in `plugin-ids` (4,2,3,6,5,7,8,9) has a
# matching /plugins/plugin-N entry, which is what keeps the "(null)" dialog
# away.
#
# force = true: xfconfd writes runtime state back into these XMLs (panel
# tweaks, window positions), and home-manager by default skips replacing files
# modified externally since activation. force makes the declarative file win on
# every rebuild — the "self-healing" behaviour the old boot-time tmpfiles wipe
# provided, now at rebuild time (same philosophy as plasma-manager's
# overrideConfig).
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    # Extra apps the stock XFCE session doesn't ship (mirroring Plasma's
    # dolphin/konsole/gwenview). These used to be system packages in
    # modules/features/xfce.nix; moved here so the whole XFCE stack is
    # user-managed.
    home.packages = lib.mkIf (osConfig.mySystem.desktop == "xfce") (with pkgs; [
      xfce4-terminal
      xfce4-screenshooter
      xfce4-clipman-plugin
      xfce4-whiskermenu-plugin
      mousepad
    ]);

    xdg.configFile = lib.mkIf (osConfig.mySystem.desktop == "xfce") {
      # Panel: the user's own working XFCE panel config, embedded verbatim.
      "xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" = {
        force = true;
        text = ''
          <?xml version="1.1" encoding="UTF-8"?>

          <channel name="xfce4-panel" version="1.0">
            <property name="configver" type="int" value="2"/>
            <property name="panels" type="array">
              <value type="int" value="1"/>
              <property name="dark-mode" type="bool" value="true"/>
              <property name="panel-1" type="empty">
                <property name="position" type="string" value="p=8;x=960;y=985"/>
                <property name="length" type="uint" value="100"/>
                <property name="position-locked" type="bool" value="true"/>
                <property name="icon-size" type="uint" value="16"/>
                <property name="size" type="uint" value="26"/>
                <property name="plugin-ids" type="array">
                  <value type="int" value="4"/>
                  <value type="int" value="2"/>
                  <value type="int" value="3"/>
                  <value type="int" value="6"/>
                  <value type="int" value="5"/>
                  <value type="int" value="7"/>
                  <value type="int" value="8"/>
                  <value type="int" value="9"/>
                </property>
              </property>
            </property>
            <property name="plugins" type="empty">
              <property name="plugin-2" type="string" value="tasklist">
                <property name="grouping" type="uint" value="1"/>
              </property>
              <property name="plugin-3" type="string" value="separator">
                <property name="expand" type="bool" value="true"/>
                <property name="style" type="uint" value="0"/>
              </property>
              <property name="plugin-6" type="string" value="systray">
                <property name="square-icons" type="bool" value="true"/>
                <property name="known-legacy-items" type="array">
                  <value type="string" value="ethernet network connection “wired connection 1” active"/>
                </property>
              </property>
              <property name="plugin-7" type="string" value="separator">
                <property name="style" type="uint" value="0"/>
              </property>
              <property name="plugin-8" type="string" value="clock"/>
              <property name="plugin-9" type="string" value="separator">
                <property name="style" type="uint" value="0"/>
              </property>
              <property name="plugin-4" type="string" value="whiskermenu">
                <property name="show-button-title" type="bool" value="true"/>
                <property name="button-title" type="string" value=" Apps"/>
                <property name="position-categories-horizontal" type="bool" value="false"/>
                <property name="position-categories-alternate" type="bool" value="true"/>
                <property name="position-profile-alternate" type="bool" value="true"/>
                <property name="position-search-alternate" type="bool" value="true"/>
                <property name="position-commands-alternate" type="bool" value="false"/>
                <property name="hover-switch-category" type="bool" value="true"/>
              </property>
              <property name="plugin-5" type="string" value="xfce4-clipman-plugin"/>
            </property>
          </channel>
        '';
      };

      # Super (Meta) key opens the Whisker menu. The whiskermenu plugin (2.8+)
      # dropped its own `super-key` xfconf option, so bind the bare key via the
      # keyboard-shortcuts channel: xfce4-popup-whiskermenu pops the menu
      # (needs plugin-4 whiskermenu in the panel above).
      "xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" = {
        force = true;
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>

          <channel name="xfce4-keyboard-shortcuts" version="1.0">
            <property name="commands" type="empty">
              <property name="custom" type="empty">
                <property name="<Super>" type="string" value="xfce4-popup-whiskermenu"/>
              </property>
            </property>
          </channel>
        '';
      };

      # Window manager (xfwm4): WhiteSur-Dark decorations to match the GTK
      # side, minimize/maximize/close on the right, and the built-in
      # compositor (no separate picom needed).
      "xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" = {
        force = true;
        text = ''
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
      };

      # xsettingsd: keep XFCE's GTK/icon/cursor choices in sync with the
      # home-manager gtk module (themes.nix) so panels, menus and dialogs all
      # render WhiteSur dark.
      "xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" = {
        force = true;
        text = ''
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
      };

      # Screensaver (xfce4-screensaver): disabled entirely — no blanking, no
      # lock after idle, and no lock on suspend. The DPMS monitor power-off is
      # also off (the monitor stays on; that's the whole point).
      "xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml" = {
        force = true;
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>

          <channel name="xfce4-screensaver" version="1.0">
            <property name="saver" type="empty">
              <property name="enabled" type="bool" value="false"/>
              <property name="mode" type="int" value="0"/>
              <property name="timeout" type="int" value="10"/>
            </property>
            <property name="lock" type="empty">
              <property name="enabled" type="bool" value="false"/>
              <property name="lock-screen-suspend" type="bool" value="false"/>
              <property name="dpms-enabled" type="bool" value="false"/>
            </property>
          </channel>
        '';
      };
    };
  };
}