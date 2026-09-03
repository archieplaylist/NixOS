# User packages — gated on mySystem.appGroups.*
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    programs.vscode = lib.mkIf osConfig.mySystem.appGroups.editor.enable {
      enable = true;
      package = pkgs.unstable.vscode;
    };

    home.packages = lib.mkMerge [
      (with pkgs; [
        fzf
        bat
        eza
        fastfetch
        btop
        exfatprogs
        ntfs3g
        zip
        unrar
        file-roller
      ])
      (lib.mkIf osConfig.mySystem.appGroups.dev.enable (with pkgs; [
        git
        lazygit
        nodejs
        gh
        python3
        gnumake
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.browsers.enable (with pkgs; [
        firefox
        vivaldi
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.media.enable (with pkgs; [
        vlc
        mpv
        yt-dlp
        ffmpeg
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.office.enable (with pkgs; [
        joplin-desktop
        onlyoffice-desktopeditors
        libreoffice-fresh
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.comms.enable (with pkgs; [
        pkgs.unstable.discord
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
        heroic
        mangohud
        protonup-qt
        (pkgs.unstable.bottles.override { removeWarningPopup = true; })
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
        chromium
        dbeaver-bin
        remmina
        filezilla
        gnumake
      ]))
    ];

    # ponytail: nixpkgs VirtualBox wrapper clobbers XDG_DATA_DIRS to its own
    # empty share → GSettings can't find org.gtk.Settings.FileChooser → Qt's
    # GTK3 dialog aborts on launch. GSettings reads the user data dir
    # (~/.local/share/glib-2.0/schemas) regardless of XDG_DATA_DIRS, so
    # symlink gtk3's compiled schemas there. No VirtualBox rebuild needed.
    xdg.dataFile = lib.mkIf osConfig.mySystem.appGroups.work.enable {
      "glib-2.0/schemas/gschemas.compiled".source =
        "${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}/glib-2.0/schemas/gschemas.compiled";
    };
  };
}
