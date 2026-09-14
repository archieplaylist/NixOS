# mario home desktops: GNOME dconf (gnome), niri+noctalia (niri),
# XFCE packages (xfce), GTK/icon/cursor theming (themes, GNOME only).
# Sections merged, behavior unchanged.
_: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: lib.mkMerge [
    {
      dconf = {
        enable = osConfig.mySystem.desktop == "gnome";
        settings = lib.mkIf (osConfig.mySystem.desktop == "gnome") {
          "org/gnome/shell" = {
            enabled-extensions = map (e: e.uuid) osConfig.mySystem.gnomeExtensions;
          };
          "org/gnome/shell/extensions/user-theme" = {
            name = "Orchis-Dark";
          };
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
            resize-with-right-button = true;
          };
          "org/gnome/desktop/interface" = {
            gtk-enable-primary-paste = true;
            monospace-font-name = "JetBrainsMono Nerd Font 11";
            document-font-name = "Noto Sans 11";
          };
          "org/gnome/desktop/sound" = {
            allow-volume-above-100-percent = true;
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${./assets/wallpaper.jpg}";
            picture-uri-dark = "file://${./assets/wallpaper.jpg}";
            picture-options = "zoom";
          };
        };
      };
    }

    (lib.mkIf (osConfig.mySystem.desktop == "niri") {
      # ponytail: unstable niri validates, same package that runs the session
      xdg.configFile."niri/config.kdl".source = pkgs.runCommand "niri-config-checked"
        {
          nativeBuildInputs = [ pkgs.unstable.niri ];
        } ''
        niri validate --config ${./assets/niri/config.kdl}
        cp ${./assets/niri/config.kdl} $out
      '';
      # ponytail: noctalia merges every *.toml here; GUI settings.toml still wins
      xdg.configFile."noctalia/wallpaper.toml".text = ''
        [wallpaper.default]
        path = "/home/mario/Pictures/Wallpapers/wallpaper.jpg"
      '';
      # ponytail: builtin alacritty colors follow noctalia palette; alacritty.toml stays unmanaged so noctalia can own its include
      xdg.configFile."noctalia/app-themes.toml".text = ''
        [theme.templates]
        enable_builtin_templates = true
        builtin_ids = ["alacritty"]
      '';
      home.file."Pictures/Wallpapers/wallpaper.jpg".source = ./assets/wallpaper.jpg;
      # ponytail: Bibata everywhere — cursor{} in config.kdl, GTK/XCURSOR here
      home.pointerCursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
        gtk.enable = true;
      };
      gtk = {
        enable = true;
        font = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
          size = 10;
        };
        cursorTheme = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
        };
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
      };
      # ponytail: ly PAM unlock is flaky — user daemon guarantees secrets+ssh socket
      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" "ssh" ];
      };
      # ponytail: niri has no auth agent; without this keyring/polkit prompts hang
      systemd.user.services.polkit-gnome-authentication-agent-1 = {
        Unit = {
          Description = "Polkit GNOME authentication agent";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })

    (lib.mkIf (osConfig.mySystem.desktop == "xfce") {
      home.packages = with pkgs; [
        xfce4-terminal
        xfce4-screenshooter
        xfce4-clipman-plugin
        xfce4-whiskermenu-plugin
        xfce4-power-manager
        xfce4-appfinder
        mousepad
        seahorse
        # ponytail: packages only, no declarative config — set manually in Appearance
        orchis-theme
        tela-circle-icon-theme
        bibata-cursors
      ];
    })

    # GTK/icon/cursor/font theming — full set on GNOME, font shared with niri (xfce stock)
    # Orchis-Dark / Tela-circle-dark / Bibata (Orchis https://github.com/vinceliuice/Orchis-theme)
    (lib.mkIf (osConfig.mySystem.desktop == "gnome") {
      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        font = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
          size = 10;
        };
        theme = {
          name = "Orchis-Dark";
          package = pkgs.orchis-theme;
        };
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
        cursorTheme = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 20;
        };
        gtk2.force = true;
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    })
  ];
}
