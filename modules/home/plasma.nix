# KDE Plasma: fully declarative via plasma-manager, active only when this host
# runs Plasma (mySystem.desktop == "plasma"; see modules/features/mySystem.nix).
#
# WhiteSur dark look to match the GTK side (modules/home/themes.nix): theme
# assets come from pkgs.whitesur-kde (installed via home.packages so Plasma can
# find the look-and-feel, desktop theme and Aurorae decorations at runtime),
# plus the already-installed whitesur-icon-theme / whitesur-cursors.
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    # The WhiteSur theme files live in the user environment so Plasma's theme
    # lookup (via XDG_DATA_DIRS) finds them. Without this, lookAndFeel and the
    # decorations silently fall back to Plasma defaults.
    home.packages = lib.mkIf (osConfig.mySystem.desktop == "plasma") [
      pkgs.whitesur-kde
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

      # WhiteSur dark theme stack. `lookAndFeel` applies the global theme;
      # the explicit settings below win over its defaults.
      workspace = {
        lookAndFeel = "com.github.vinceliuice.WhiteSur-dark";
        theme = "WhiteSur-dark";
        colorScheme = "${pkgs.whitesur-kde}/share/color-schemes/WhiteSurDark.colors";
        iconTheme = "WhiteSur-dark";
        cursor = {
          theme = "WhiteSur-cursors";
          size = 24;
        };
        windowDecorations = {
          library = "org.kde.kwin.aurorae.v2";
          theme = "__aurorae__svg__WhiteSur-dark";
        };
        wallpaper = "${pkgs.whitesur-kde}/share/wallpapers/WhiteSur-dark/contents/images/3840x2160.jpg";
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
