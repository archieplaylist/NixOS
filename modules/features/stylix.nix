# Stylix — single base16 scheme for the whole desktop (replaces WhiteSur).
#
# Generates GTK, icon, cursor, font, wallpaper, GNOME Shell, Plasma (Breeze),
# XFCE (xfsettings/xfwm4), Qt (qtct) and LightDM theming from one palette.
# Hosts keep `mySystem.desktop` switching; Stylix just follows.
# 
# Flatpak theming: `stylix.targets.gtk.flatpakSupport` (HM) exposes the
# generated GTK theme/icons/cursors to sandboxed apps. The NixOS flatpak
# overrides below also expose `xdg-config/gtk-*`, `xdg-data/icons` and
# `xdg-data/themes` plus `XCURSOR_PATH`/`GTK_THEME` so GTK *and* Qt flatpaks
# pick up the Stylix theme regardless of DE (GNOME/Plasma/XFCE).
#
# Change the palette by swapping `base16Scheme` (any file under
# pkgs.base16-schemes/share/themes/*.yaml) or set `image = ./wallpaper.jpg`
# and remove `base16Scheme` to auto-generate from wallpaper. `polarity = "dark"`
# keeps the generated palette dark when using an image.
{ ... }:
{
  config.nixos.modules.stylix = { config, pkgs, lib, ... }: {
    stylix = {
      enable = true;
      polarity = "dark";
      # Gruvbox Dark Hard — matches gruvbox hard elsewhere (nvim etc.).
      # Swap for any file in pkgs.base16-schemes/share/themes/*.yaml
      # or delete and set `image = ./wallpaper.jpg` to auto-generate.
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
      # image = pkgs.fetchurl {
      #   url = "https://example.com/wallpaper.jpg";
      #   hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      # };
      imageScalingMode = "fill";
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };
      icons = {
        enable = true;
        package = pkgs.papirus-icon-theme;
        dark = "Papirus-Dark";
        light = "Papirus";
      };
      fonts = {
        sansSerif = { package = pkgs.noto-fonts; name = "Noto Sans"; };
        serif = { package = pkgs.noto-fonts; name = "Noto Serif"; };
        monospace = { package = pkgs.jetbrains-mono; name = "JetBrainsMono Nerd Font"; };
        emoji = { package = pkgs.noto-fonts-color-emoji; name = "Noto Color Emoji"; };
        sizes = {
          applications = 11;
          desktop = 10;
          popups = 10;
          terminal = 11;
        };
      };
      opacity = {
        applications = 1.0;
        desktop = 1.0;
        popups = 1.0;
        terminal = 0.95;
      };
      # Auto-enabled targets (autoEnable=true) already cover gtk/qt/gnome/
      # xfce/kde/lightdm, but be explicit so intent is clear and survives
      # `autoEnable = false` if the user flips it.
      # GNOME + KDE need stylix on both HM and NixOS; NixOS greeters need
      # lightdm/gdm/sddm wiring — set all so switching DE doesn't lose palette.
      targets = {
        gnome.enable = true; # also GDM greeter
        kde.enable = true;
        xfce.enable = true;
        gtk.enable = true;
        qt.enable = true;
        lightdm.enable = true;
        grub.enable = true;
        console.enable = true;
      };
    };

    # Flatpak: expose the Stylix-generated theme to sandboxed apps.
    # HM's `gtk.flatpakSupport` does the user-side portal bits; these
    # system-wide overrides make the theme visible to *all* flatpaks
    # (GTK and Qt) regardless of whether they run as system or user installs.
    # nix-flatpak merges this with per-app overrides from `mySystem.flatpakApps`.
    services.flatpak.overrides.settings.global = {
      Context.filesystems = [
        "xdg-config/gtk-3.0:ro"
        "xdg-config/gtk-4.0:ro"
        "xdg-data/icons:ro"
        "xdg-data/themes:ro"
        "xdg-config/Kvantum:ro"
        "xdg-config/qt5ct:ro"
        "xdg-config/qt6ct:ro"
      ];
      Environment = {
        XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
      };
    };
  };

  # Home Manager side — inherits the NixOS palette via
  # `stylix.homeManagerIntegration.followSystem` (default true). Explicit
  # target toggles here ensure Qt + Flatpak get themed even if autoEnable is off.
  # NOTE: stylix xfce module has `autoEnable = false` (upstream issue #180), so
  # it MUST be forced on. The xfconf channels below hand Stylix real theme
  # names — with only fonts it fell back to default GTK/XFWM/cursor (Adwaita).
  config.home.modules.mario = { pkgs, ... }: {
    stylix.targets = {
      gtk.enable = true;
      gtk.flatpakSupport.enable = true;
      qt.enable = true;
      qt.platform = "qtct";
      kde.enable = true;
      xfce.enable = true;
      gnome.enable = true;
    };
    # Stylix xfce only sets fonts; feed xfconf the Stylix GTK/XFWM/icon/cursor
    # names so xsettings (Net/ThemeName, IconThemeName, CursorThemeName) and
    # xfwm4 (general/theme) don't stay Adwaita/default.
    # adw-gtk3 is Stylix's GTK theme; xfwm needs an xfwm4 theme — Default is
    # always present (built into xfwm4) so it won't fallback to "(default)".
    # Papirus-Dark comes from stylix.icons (added above); Bibata from stylix.cursor.
    xfconf.settings = {
      xsettings = {
        "Net/ThemeName" = "adw-gtk3";
        "Net/IconThemeName" = "Papirus-Dark";
        "Gtk/CursorThemeName" = "Bibata-Modern-Classic";
        "Gtk/CursorThemeSize" = 24;
      };
      xfwm4."general/theme" = "Default";
    };
    # Fallback: ensure themes/icons/cursors are actually on disk even if
    # Stylix's auto-install is missed (HM vs NixOS split). Papirus was
    # missing in /run/current-system/sw/share/icons.
    home.packages = with pkgs; [ papirus-icon-theme bibata-cursors ];
  };
}
