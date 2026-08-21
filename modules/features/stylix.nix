# Stylix — single base16 scheme for the whole desktop (replaces WhiteSur +
# gruvbox). Adapted from the reference config: custom GitHub-dark-flavoured
# base16 palette, Fira Mono Nerd Font, Fluent icons, Bibata-Original cursor.
#
# Themes GTK (adw-gtk3 + generated gtk.css in the custom palette), GNOME Shell,
# Plasma (Breeze from the palette), XFCE (xfconf), Qt (qtct), LightDM/grub/
# console, plus app targets (vscode, kitty, firefox, vesktop, helix, yazi,
# obsidian) and Flatpak apps via nix-flatpak overrides. Hosts keep
# `mySystem.desktop` switching; Stylix just follows.
#
# Re-theme by replacing `base16Scheme` below, or set `image = ./wallpaper.jpg`
# and delete `base16Scheme` to auto-generate from a wallpaper (`polarity`
# stays dark).
{ ... }:
{
  config.nixos.modules.stylix = { config, pkgs, lib, ... }: {
    stylix = {
      enable = true;
      polarity = "dark";
      # Custom palette (GitHub-dark-flavoured, from the reference config).
      # Replace this whole attrset to re-theme, or set `image = ./wallpaper.jpg`
      # and delete base16Scheme to auto-generate from a wallpaper.
      base16Scheme = {
        base00 = "111418";
        base01 = "181c22";
        base02 = "1f242b";
        base03 = "6e7681";
        base04 = "8b97a3";
        base05 = "c9d1d9";
        base06 = "e6e9ed";
        base07 = "f0f2f5";
        base08 = "be5a55";
        base09 = "be825a";
        base0A = "c8aa5a";
        base0B = "6eaa82";
        base0C = "5aaaaf";
        base0D = "6ea8e0";
        base0E = "aa82aa";
        base0F = "a892b8";
      };
      imageScalingMode = "fill";

      fonts = {
        monospace = { package = pkgs.nerd-fonts.fira-mono; name = "Fira Mono Nerd Font"; };
        sansSerif = { package = pkgs.nerd-fonts.fira-mono; name = "Fira Mono Nerd Font"; };
        serif = { package = pkgs.nerd-fonts.fira-mono; name = "Fira Mono Nerd Font"; };
        emoji = { package = pkgs.noto-fonts-color-emoji; name = "Noto Color Emoji"; };
        sizes = {
          applications = 14;
          desktop = 14;
          popups = 12;
          terminal = 16.5;
        };
      };

      icons = {
        enable = true;
        package = pkgs.fluent-icon-theme;
        dark = "Fluent";
        light = "Fluent";
      };

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Original-Classic";
        size = 22;
      };

      opacity = {
        applications = 1.0;
        desktop = 1.0;
        popups = 1.0;
        terminal = 1.0;
      };

      # All DE targets explicit so switching mySystem.desktop keeps the palette.
      targets = {
        gnome.enable = true; # also GDM greeter
        kde.enable = true;
        xfce.enable = true;
        gtk.enable = true;
        qt.enable = true;
        qt.platform = lib.mkForce "qtct";
        lightdm.enable = true;
        grub.enable = true;
        console.enable = true;
      };
    };

    # Theme/icon/cursor packages on the SYSTEM profile so
    # /run/current-system/sw/share/{themes,icons} has them (XFCE + flatpaks
    # read these). adw-gtk3 is Stylix's GTK base theme (custom colors come
    # from the generated gtk.css).
    environment.systemPackages = with pkgs; [ fluent-icon-theme bibata-cursors adw-gtk3 ];
    # Flatpak theming (system installs via nix-flatpak):
    #  - GTK flatpaks: GTK_THEME=adw-gtk3 + xdg-config/gtk-{3,4}.0 exposed so
    #    they load the same generated gtk.css (custom palette), plus the theme
    #    in ~/.local/share/themes (HM xdg.dataFile) via xdg-data/themes.
    #  - Qt flatpaks: QT_QPA_PLATFORMTHEME=gtk3 (bundled in qtbase) → same theme.
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
        QT_QPA_PLATFORMTHEME = "gtk3";
        GTK_THEME = "adw-gtk3";
      };
    };
  };

  # Home Manager side — inherits the NixOS palette via
  # `stylix.homeManagerIntegration.followSystem` (default true). Explicit
  # target toggles here ensure Qt + Flatpak get themed even if autoEnable is off.
  # NOTE: stylix xfce module has `autoEnable = false` (upstream issue #180), so
  # it MUST be forced on. The xfconf channels below hand Stylix real theme
  # names — with only fonts it fell back to default GTK/XFWM/cursor (Adwaita).
  config.home.modules.mario = { pkgs, lib, ... }: {
    stylix.targets = {
      gtk.enable = true;                 # adw-gtk3 + generated gtk.css (custom palette)
      gtk.flatpakSupport.enable = false; # system flatpaks handled by NixOS overrides
      qt.enable = true;
      qt.platform = lib.mkForce "qtct";
      kde.enable = true;
      xfce.enable = true;
      gnome.enable = true;
      # App targets (from the reference config)
      vscode.enable = true;
      kitty = {
        enable = true;
        opacity.override.terminal = 0.82;
      };
      firefox = {
        enable = true;
        colorTheme.enable = true;
        profileNames = [ "default" ];
        colors.override = {
          base0D-rgb-r = "220";
          base0D-rgb-g = "240";
          base0D-rgb-b = "255";
          base0D-alpha = "0.7";
        };
      };
      vesktop.enable = true; # Discord
      helix.enable = true;
      yazi.enable = true;
      obsidian.enable = true;
    };

    # XFCE: feed xfconf explicit names — Stylix's xfce module only sets fonts,
    # so without this the GTK/icon/cursor stay at defaults.
    xfconf.settings = {
      xsettings = {
        "Net/ThemeName" = "adw-gtk3-dark";
        "Net/IconThemeName" = "Fluent";
        "Gtk/CursorThemeName" = "Bibata-Original-Classic";
        "Gtk/CursorThemeSize" = 22;
      };
      xfwm4."general/theme" = "Default";
    };

    # Ensure themes/icons/cursors are on disk even if Stylix's auto-install is
    # missed (HM vs NixOS split).
    home.packages = with pkgs; [ fluent-icon-theme bibata-cursors adw-gtk3 ];
    # Drop adw-gtk3 into ~/.local/share/themes so flatpaks (exposed via
    # xdg-data/themes:ro) can load it, on top of the generated gtk.css they
    # reach via xdg-config/gtk-{3,4}.0:ro.
    xdg.dataFile."themes/adw-gtk3" = {
      source = "${pkgs.adw-gtk3}/share/themes/adw-gtk3";
    };
    # Force dark for GTK/libadwaita under every DE (XFCE reads dconf too).
    # Same value Stylix's gnome target writes, so they merge cleanly.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
