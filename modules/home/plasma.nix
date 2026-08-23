# Plasma via plasma-manager — Nordic dark, only when desktop == plasma
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }:
    let
      # Nordic ships metadata.desktop, Plasma 6 needs metadata.json for lookAndFeel discovery
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
      home.packages = lib.mkIf (osConfig.mySystem.desktop == "plasma") [
        pkgs.kitty
        nordic
      ];

      programs.plasma = lib.mkIf (osConfig.mySystem.desktop == "plasma") {
        enable = true;
        overrideConfig = true;

        session = {
          sessionRestore = {
            restoreOpenApplicationsOnLogin = "startWithEmptySession";
          };
        };

        configFile."kwalletrc" = {
          Wallet = {
            Enabled = true;
            "First Use" = false;
          };
        };

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

        # Explicit theme components — don't use workspace.lookAndFeel (wipes Aurorae in Plasma 6)
        workspace = {
          theme = "Nordic";
          colorScheme = "${nordic}/share/color-schemes/Nordic.colors";
          iconTheme = "Papirus-Dark";
          cursor = {
            theme = "Bibata-Modern-Classic";
            size = 24;
          };
          windowDecorations = {
            library = "org.kde.kwin.aurorae.v2";
            theme = "__aurorae__svg__Nordic";
          };
          wallpaper = "${./assets/wallpaper.png}";
        };

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
            "Window Close" = "Meta+Q";
          };
        };
      };
    };
}
