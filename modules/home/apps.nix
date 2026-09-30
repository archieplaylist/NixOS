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

      home.packages = lib.mkMerge [
        (with pkgs; [
          bat
          btop
          exfatprogs
          fastfetch
          file-roller
          fzf
          ntfs3g
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
          gh
          git
          go # mason builds gopls/goimports/delve from source; without it every Go server install fails
          gnumake
          lazygit
          nodejs
          python3
          ripgrep # telescope live grep
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
          joplin-desktop
          libreoffice-fresh
          onlyoffice-desktopeditors
          zoom-us
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.comms.enable (with pkgs; [
          unstable.discord
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
          heroic
          mangohud
          unstable.protonplus
          (unstable.bottles.override { removeWarningPopup = true; })
        ]))
        (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
          chromium
          dbeaver-bin
          filezilla
          remmina
        ]))
        (lib.mkIf osConfig.mySystem.enableMoonlight (with pkgs; [
          moonlight-qt
        ]))
      ];

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
