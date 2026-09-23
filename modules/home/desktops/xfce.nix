# primary home xfce: packages + declarative settings seed.
# System-wide xfconf defaults live in /etc/xdg (see features/desktop.nix);
# this seed copies the same channel files into
# ~/.config/xfce4/xfconf/xfce-perchannel-xml/ only when missing, so a wiped
# home dir is restored on the next rebuild while user GUI edits always win.
# To re-adopt a changed Nix default, delete the user channel file and rebuild.
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "xfce") {
    home.packages = with pkgs; [
      xfce4-terminal
      xfce4-screenshooter
      xfce4-clipman-plugin
      xfce4-whiskermenu-plugin
      xfce4-power-manager
      xfce4-appfinder
      mousepad
      seahorse
      # packages only, no declarative config — set manually in Appearance
      orchis-theme
      tela-circle-icon-theme
      bibata-cursors
    ];

    # Copy-if-missing seed of the declarative channel files (same set as the
    # /etc/xdg system defaults in features/desktop.nix). Never overwrites:
    # xfconfd already prefers user values, and this keeps GUI edits intact.
    home.activation.seedXfceDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      xfce_xml_dir="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
      $DRY_RUN_CMD mkdir -p "$xfce_xml_dir"
      ${lib.concatMapStringsSep "\n" (name: ''
        if [ ! -e "$xfce_xml_dir/${name}.xml" ]; then
          $DRY_RUN_CMD install -Dm644 "${../assets/xfce/${name}.xml}" "$xfce_xml_dir/${name}.xml"
        fi
      '') [ "xsettings" "xfwm4" "xfce4-desktop" "xfce4-session" "xfce4-power-manager" "keyboards" "thunar" ]}
    '';

    xdg.configFile."alacritty/alacritty.toml".text = ''
      [window]
      padding = { x = 12, y = 12 }
      opacity = 0.80

      [font]
      size = 11

      [font.normal]
      family = "JetBrainsMono Nerd Font"
    '';
  };
}
