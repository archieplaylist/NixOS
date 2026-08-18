# XFCE: declarative via xfconf XML files, active only when this host runs XFCE
# (mySystem.desktop == "xfce"; see modules/features/mySystem.nix). XFCE stores
# its settings in per-channel XML files under
# ~/.config/xfce4/xfconf/xfce-perchannel-xml/ — writing them via home.file is
# the home-manager equivalent of plasma-manager for Plasma. Runtime tweaks via
# the XFCE settings dialogs are overwritten by the next rebuild (that's the
# point).
#
# The WhiteSur dark look matches the rest of the stack (modules/home/themes.nix):
# xfwm4 finds the WhiteSur-Dark window theme through XDG_DATA_DIRS because
# home-manager's gtk module installs whitesur-gtk-theme into the user
# environment (same mechanism plasma.nix documents for whitesur-kde).
{ ... }: {
  config.home.modules.mario = { lib, osConfig, ... }: {
    home.file = lib.mkIf (osConfig.mySystem.desktop == "xfce") {
      # Window manager (xfwm4): WhiteSur-Dark decorations to match the GTK
      # side, minimize/maximize/close on the right, and the built-in
      # compositor (no separate picom needed).
      ".config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
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
      ".config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
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

      # Panel: a minimal single bottom panel (applications menu, tasklist,
      # clock, system tray). Plugin IDs are arbitrary unique integers; the
      # launcher/pager plugins are deliberately omitted because their items are
      # easy to get wrong by hand — add them by editing this XML (or removing
      # this file to fall back to the stock panel, which xfce4-panel
      # regenerates on first login).
      ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfce4-panel" version="1.0">
          <property name="configver" type="int" value="2"/>
          <property name="panels" type="array">
            <value type="int" value="1"/>
            <property name="panel-1" type="empty">
              <property name="length" type="uint" value="100"/>
              <property name="size" type="uint" value="40"/>
              <property name="plugin-ids" type="array">
                <value type="int" value="1"/>
                <value type="int" value="2"/>
                <value type="int" value="3"/>
                <value type="int" value="4"/>
              </property>
            </property>
          </property>
          <property name="plugins" type="empty">
            <property name="plugin-1" type="empty">
              <property name="type" type="string" value="applicationsmenu"/>
            </property>
            <property name="plugin-2" type="empty">
              <property name="type" type="string" value="tasklist"/>
            </property>
            <property name="plugin-3" type="empty">
              <property name="type" type="string" value="clock"/>
              <property name="digital-time-format" type="string" value="%H:%M"/>
            </property>
            <property name="plugin-4" type="empty">
              <property name="type" type="string" value="systray"/>
            </property>
          </property>
        </channel>
      '';
    };
  };
}
