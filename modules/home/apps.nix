# User packages — gated on mySystem.appGroups.*
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: {
    programs.vscode = lib.mkIf osConfig.mySystem.appGroups.editor.enable {
      enable = true;
      # Electron cannot pick backend on niri (XDG_CURRENT_DESKTOP=niri) — force libsecret so Login keyring stores tokens
      package = pkgs.unstable.vscode.override {
        commandLineArgs = "--password-store=gnome-libsecret";
      };
    };

    home.packages = lib.mkMerge [
      (with pkgs; [
        fzf
        bat
        fastfetch
        btop
        zip
        unrar
        file-roller
      ])
      (lib.mkIf (osConfig.mySystem.desktop == "gnome" || osConfig.mySystem.desktop == "niri") (with pkgs; [
        nautilus
      ]))
      # no USB disks in vm guest
      (lib.mkIf (!osConfig.mySystem.isVm) (with pkgs; [
        exfatprogs
        ntfs3g
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.dev.enable (with pkgs; [
        git
        lazygit
        nodejs
        gh
        python3
        gnumake
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.browsers.enable [
        pkgs.firefox
        # Chromium picks backend from XDG_CURRENT_DESKTOP (kwallet on plasma, basic store on niri) — force libsecret so Login keyring stores tokens, same as vscode above
        (pkgs.vivaldi.override { commandLineArgs = "--password-store=gnome-libsecret"; })
      ])
      (lib.mkIf osConfig.mySystem.appGroups.media.enable (with pkgs; [
        vlc
        mpv
        yt-dlp
        ffmpeg
        pkgs.unstable.qbittorrent
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.office.enable (with pkgs; [
        joplin-desktop
        onlyoffice-desktopeditors
        libreoffice-fresh
        zoom-us
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.comms.enable (with pkgs; [
        pkgs.unstable.discord
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
        heroic
        mangohud
        pkgs.unstable.protonplus
        (pkgs.unstable.bottles.override { removeWarningPopup = true; })
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
        chromium
        dbeaver-bin
        remmina
        filezilla
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
    xdg.dataFile =
      let
        gtkSchema = "${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}/glib-2.0/schemas/gschemas.compiled";
      in
      lib.mkIf (osConfig.mySystem.appGroups.work.enable && builtins.pathExists gtkSchema) {
        "glib-2.0/schemas/gschemas.compiled".source = gtkSchema;
      };
    warnings =
      let
        gtkSchema = "${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}/glib-2.0/schemas/gschemas.compiled";
      in
      lib.optional (osConfig.mySystem.appGroups.work.enable && !(builtins.pathExists gtkSchema))
        "gtk3 gsettings path moved — update the VirtualBox workaround in apps.nix";
  };
}
