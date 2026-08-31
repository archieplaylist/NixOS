# User packages — gated on mySystem.appGroups.*
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    programs.vscode = lib.mkIf osConfig.mySystem.appGroups.editor.enable {
      enable = true;
      package = pkgs.unstable.vscode; # ponytail: stable 1.119 lags unstable 1.133 — same overlay as discord
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
  };
}
