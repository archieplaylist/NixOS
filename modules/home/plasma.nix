# Plasma via plasma-manager — Nordic dark, only when desktop == plasma
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    home.packages = lib.mkIf (osConfig.mySystem.desktop == "plasma") [
      pkgs.kitty
      pkgs.nordic
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
        colorScheme = "Nordic"; # ponytail: string not store path
        iconTheme = "Papirus-Dark";
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 20;
        };
        windowDecorations = {
          library = "org.kde.kwin.aurorae.v2";
          theme = "__aurorae__svg__Nordic";
        };
        wallpaper = "${./assets/wallpaper.png}";
      };

      configFile.kwinrc = {
        Compositing = {
          Backend = "OpenGL";
          LatencyPolicy = "low";
          GLPreferBufferSwap = "a";
          WindowsBlockCompositing = true;
        };
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
