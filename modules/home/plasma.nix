# KDE Plasma: fully declarative via plasma-manager, active only when this host
# runs Plasma (mySystem.desktop == "plasma"; see modules/features/mySystem.nix).
#
# Stylix now owns the theme (Breeze + generated palette, modules/features/stylix.nix).
# plasma-manager keeps layout/input/shortcuts; colors/icons/cursor/wallpaper
# come from Stylix so GTK/Qt/Plasma share one base16 scheme.
{ ... }: {
  config.home.modules.mario = { lib, osConfig, ... }: {

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

      # Appearance: Stylix provides a full lookAndFeel package "Stylix"
      # (Breeze colorscheme + wallpaper, see stylix kde hm.nix) via
      # `stylix.targets.kde`. With plasma-manager `overrideConfig = true`,
      # leaving workspace{} empty makes Plasma regenerate defaults that can
      # mask Stylix's lookAndFeel. Must not set workspace.lookAndFeel/theme
      # here — Stylix writes kdeglobals/lookAndFeel via themePackage. If you
      # need a non-Stylix Plasma theme, set `stylix.targets.kde.enable = false`.
      # Intentionally no workspace.lookAndFeel here.

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
