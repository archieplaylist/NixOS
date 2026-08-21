# KDE Plasma: fully declarative via plasma-manager, active only when this host
# runs Plasma (mySystem.desktop == "plasma"; see modules/features/mySystem.nix).
#
# Nordic dark look to match the GTK side (modules/home/themes.nix): theme
# assets come from pkgs.nordic (installed via home.packages so Plasma can find
# the look-and-feel, desktop theme and Aurorae decorations at runtime), plus
# papirus-icon-theme / bibata-cursors.
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    let
      # Plasma 6 discovers global themes (KPackage type "Plasma/LookAndFeel")
      # by scanning for metadata.json — but pkgs.nordic only ships
      # metadata.desktop, so `plasma-apply-lookandfeel -a Nordic` reports
      # "Unable to find the theme named Nordic" and the theme is absent from
      # System Settings → Global Theme. Bake a metadata.json into the
      # look-and-feel dirs so the Nordic global theme is discoverable and
      # selectable. (We don't auto-apply it via `workspace.lookAndFeel` — see
      # the comment in the workspace block below — but it's available for
      # manual selection and any future use.)
      nordicMetadata = theme: pkgs.writeText "nordic-${theme}-lf-metadata.json" (builtins.toJSON {
        KPackageStructure = "Plasma/LookAndFeel";
        KPlugin = {
          Id = theme;
          Name = theme;
          Version = "0.1";
          Category = "Plasma Look And Feel";
          ServiceTypes = [ "Plasma/LookAndFeel" ];
        };
      });
      nordic = pkgs.nordic.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          cp ${nordicMetadata "Nordic"} "$out/share/plasma/look-and-feel/Nordic/metadata.json"
          cp ${nordicMetadata "Nordic-bluish"} "$out/share/plasma/look-and-feel/Nordic-bluish/metadata.json"
          cp ${nordicMetadata "Nordic-darker"} "$out/share/plasma/look-and-feel/Nordic-darker/metadata.json"
        '';
      });
    in
    {
      # The Nordic theme files live in the user environment so Plasma's theme
      # lookup (via XDG_DATA_DIRS) finds them.
      home.packages = lib.mkIf (osConfig.mySystem.desktop == "plasma") [
        nordic
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

        # Nordic dark theme stack. We deliberately do NOT auto-apply the
        # global theme (`workspace.lookAndFeel`): plasma-manager's apply
        # script runs `plasma-apply-lookandfeel -a Nordic` at login, which in
        # Plasma 6 wipes the explicitly-set window decorations (back to
        # Breeze). Instead every theme component is set explicitly below —
        # colors, Plasma theme, icons, cursor, decorations and wallpaper —
        # which is deterministic and survives logins. The Nordic global theme
        # itself is still installed and selectable in System Settings (see the
        # metadata.json override at the top of this module).
        workspace = {
          theme = "Nordic";
          colorScheme = "${nordic}/share/color-schemes/Nordic.colors";
          iconTheme = "Papirus-Dark";
          cursor = {
            theme = "Bibata-Modern-Classic";
            size = 24;
          };
          # Nordic Aurorae window decorations (the aurorae theme ships in the
          # same nordic package). `__aurorae__svg__Nordic` is the KDecoration2
          # id for the Aurorae SVG theme "Nordic".
          windowDecorations = {
            library = "org.kde.kwin.aurorae.v2";
            theme = "__aurorae__svg__Nordic";
          };
          # Pick the first image shipped in the Nordic wallpapers dir.
          wallpaper =
            let
              wallpapers = builtins.readDir "${nordic}/share/wallpapers/Nordic";
              images = lib.filter (n: lib.hasSuffix ".png" n || lib.hasSuffix ".jpg" n) (builtins.attrNames wallpapers);
            in
            "${nordic}/share/wallpapers/Nordic/${builtins.head images}";
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
