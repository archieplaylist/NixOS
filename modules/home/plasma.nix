# KDE Plasma: fully declarative via plasma-manager, active only when this host
# runs Plasma (mySystem.desktop == "plasma"; see modules/features/mySystem.nix).
#
# Nordic dark look to match the GTK side (modules/home/themes.nix): theme
# assets come from pkgs.nordic (installed via home.packages so Plasma can find
# the look-and-feel, desktop theme and Aurorae decorations at runtime), plus
# papirus-icon-theme / bibata-cursors.
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    # The Nordic theme files live in the user environment so Plasma's theme
    # lookup (via XDG_DATA_DIRS) finds them.
    home.packages = lib.mkIf (osConfig.mySystem.desktop == "plasma") [
      pkgs.nordic
    ];

    programs.plasma = lib.mkIf (osConfig.mySystem.desktop == "plasma") {
      enable = true;
      # Truly declarative: options not set here reset to Plasma defaults at
      # login, and all managed KDE config files are regenerated on every
      # home-manager activation. Runtime tweaks via System Settings are
      # overwritten by the next rebuild (that's the point).
      overrideConfig = true;

      # Start with an empty session at login instead of restoring the previous
      # session's open applications (ksmserverrc [General] loginMode).
      session = {
        sessionRestore = {
          restoreOpenApplicationsOnLogin = "startWithEmptySession";
        };
      };

      # KWallet: enabled, and the wallet is unlocked at SDDM login by the PAM
      # module (security.pam.services.sddm.kwallet.enable in desktop.nix) when
      # the wallet password matches the login password. `First Use=false`
      # because the kdewallet already exists; kwalletd rewrites this file.
      configFile."kwalletrc" = {
        Wallet = {
          Enabled = true;
          "First Use" = false;
        };
      };

      # Natural scrolling (macOS-style) for the built-in touchpad, matching the
      # device in /proc/bus/input/devices. Add more touchpads/mice (e.g. an
      # external mouse) the same way.
      input = {
        touchpads = [
          {
            enable = true;
            name = "SynPS/2 Synaptics TouchPad";
            vendorId = "0002";
            productId = "0007";
            naturalScroll = true;
          }
        ];
      };

      # Nordic dark theme stack. `lookAndFeel` applies the global theme
      # (colors, icons, window decorations, splash) on every login; the
      # explicit settings below win over its defaults. We deliberately do NOT
      # set `workspace.windowDecorations` here — the theme's own defaults
      # provide the Nordic Aurorae decorations, and plasma-manager warns
      # against declaring them alongside lookAndFeel.
      workspace = {
        lookAndFeel = "Nordic";
        theme = "Nordic";
        colorScheme = "${pkgs.nordic}/share/color-schemes/Nordic.colors";
        iconTheme = "Papirus-Dark";
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 24;
        };
        # Pick the first image shipped in the Nordic wallpapers dir.
        wallpaper = let
          wallpapers = builtins.readDir "${pkgs.nordic}/share/wallpapers/Nordic";
          images = lib.filter (n: lib.hasSuffix ".png" n || lib.hasSuffix ".jpg" n) (builtins.attrNames wallpapers);
        in "${pkgs.nordic}/share/wallpapers/Nordic/${builtins.head images}";
      };

      # Classic single bottom panel: launcher, pinned tasks, system tray, clock.
      panels = [
        {
          location = "bottom";
          height = 40;
          widgets = [
            "org.kde.plasma.kickoff"
            {
              iconTasks = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:org.kde.konsole.desktop"
                  "applications:firefox.desktop"
                ];
              };
            }
            "org.kde.plasma.systemtray"
            {
              digitalClock = {
                time.format = "24h";
              };
            }
          ];
        }
      ];

      shortcuts = {
        "services.org.kde.dolphin.desktop"._launch = "Meta+E";
        "services.org.kde.konsole.desktop"._launch = "Meta+Return";
        kwin = {
          "Expose" = "Meta+,";
          "Switch Window Down" = "Meta+J";
          "Switch Window Left" = "Meta+H";
          "Switch Window Right" = "Meta+L";
          "Switch Window Up" = "Meta+K";
        };
      };
    };
  };
}
