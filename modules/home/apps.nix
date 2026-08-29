# User packages — gated on mySystem.appGroups.*
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    programs.vscode = lib.mkIf osConfig.mySystem.appGroups.general.enable {
      enable = true;
      package = pkgs.vscode;
    };

    home.packages = lib.mkMerge [
      (with pkgs; [
        fzf
        bat
        eza
        fastfetch
        btop
        python3
        exfatprogs
        ntfs3g
        gparted
        zip
        unrar
        make
      ])
      (lib.mkIf osConfig.mySystem.appGroups.dev.enable (with pkgs; [
        git
        lazygit
        nodejs
        gh
        docker-compose
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.general.enable (with pkgs; [
        firefox
        chromium
        vivaldi
        vlc
        mpv
        yt-dlp
        ffmpeg
        discord
        joplin-desktop
        onlyoffice-desktopeditors
        libreoffice-fresh
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
        heroic
        cartridges
        vulkan-tools
        mangohud
        goverlay
        protonup-qt
        vkbasalt
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
        dbeaver-bin
        remmina
        filezilla
      ]))
    ];
  };
}
