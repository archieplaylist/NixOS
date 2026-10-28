# User packages — gated on mySystem.appGroups.*
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }:
    let
      gtkSchema = "${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}/glib-2.0/schemas/gschemas.compiled";
    in
    {
      programs.vscode = lib.mkIf osConfig.mySystem.appGroups.editor.enable {
        enable = true;
        # Force libsecret so VSCode stores tokens in the Login keyring regardless of DE backend detection
        package = pkgs.unstable.vscode.override {
          commandLineArgs = "--password-store=gnome-libsecret";
        };
      };

      home.sessionVariables = lib.mkIf osConfig.mySystem.appGroups.editor.enable {
        EDITOR = "code --wait";
        VISUAL = "code --wait";
      };

      home.packages = lib.mkMerge [
        (with pkgs; [
          aria2
          bat
          btop
          exfatprogs
          fastfetch
          fetch
          file-roller
          fzf
          ntfs3g
          smartmontools
          unrar
          zip
          unstable.rpi-imager
          unstable.dcmtk
        ])
        (lib.mkIf (osConfig.mySystem.desktop == "gnome") (with pkgs; [
          nautilus
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.dev.enable (with pkgs; [
          fd # telescope/snacks fuzzy file finder; falls back to find otherwise
          gcc # cgo linker for Go (xo/terminfo -> os/user); without it CGO_ENABLED must be 0
          gh
          git
          go
          gnumake
          lazygit
          nodejs
          php85
          php85Packages.composer
          phpunit
          phpstan
          php85Packages.php-cs-fixer
          python3
          ripgrep
          unstable.pnpm
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.browsers.enable [
          pkgs.firefox
          # Chromium picks backend from XDG_CURRENT_DESKTOP (kwallet on plasma) — force libsecret so Login keyring stores tokens, same as vscode above
          (pkgs.vivaldi.override { commandLineArgs = "--password-store=gnome-libsecret"; })
        ])
        (lib.mkIf osConfig.mySystem.appGroups.media.enable (with pkgs; [
          ffmpeg
          mpv
          vlc
          yt-dlp
          unstable.qbittorrent
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.office.enable (with pkgs; [
          libreoffice-fresh
          onlyoffice-desktopeditors
          unstable.joplin-desktop
          unstable.zoom-us
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.comms.enable (with pkgs; [
          # Electron/Chromium backend defaults to gnome-libsecret outside KDE —
          # no flag override needed once xfce.nix provides org.freedesktop.secrets
          unstable.discord
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
          heroic
          mangohud
          unstable.protonplus
          # bottles moved to the flatpak build (mySystem.flatpakApps, gated on gaming)
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
          chromium
          dbeaver-bin
          filezilla
          remmina
          weasis
        ]))
        (lib.mkIf osConfig.mySystem.enableMoonlight (with pkgs; [
          moonlight-qt
        ]))
      ];

      # fetch config — info fields + label color approximating fastfetch's cyan keys
      xdg.configFile."fetch/config".text = ''
        os
        host
        kernel
        uptime
        packages
        shell
        display
        wm
        terminal
        font
        theme
        icons
        cpu
        gpu
        memory
        swap
        disk
        battery
        ip
        locale
        colors
        label_color=cyan
        separator=-
      '';

      # MangoHud — only when gaming group enabled
      home.file.".config/MangoHud/MangoHud.conf" = lib.mkIf osConfig.mySystem.appGroups.gaming.enable {
        text = ''
          gpu_stats
          cpu_stats
          fps
          frametime
          temperature
        '';
      };

      # nixpkgs VirtualBox wrapper clobbers XDG_DATA_DIRS to its own
      # empty share → GSettings can't find org.gtk.Settings.FileChooser → Qt's
      # GTK3 dialog aborts on launch. GSettings reads the user data dir
      # (~/.local/share/glib-2.0/schemas) regardless of XDG_DATA_DIRS, so
      # symlink gtk3's compiled schemas there. No VirtualBox rebuild needed.
      xdg.dataFile = lib.mkIf (osConfig.mySystem.enableVirtualBox && builtins.pathExists gtkSchema) {
        "glib-2.0/schemas/gschemas.compiled".source = gtkSchema;
      };
      warnings = lib.optional (osConfig.mySystem.enableVirtualBox && !(builtins.pathExists gtkSchema))
        "gtk3 gsettings path moved — update the VirtualBox workaround in apps.nix";
    };
}
