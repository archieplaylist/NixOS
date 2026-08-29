# User packages — gated on mySystem.appGroups.*
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    programs.vscode = lib.mkIf osConfig.mySystem.appGroups.general.enable {
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
        python3 # ponytail: moved from general — only dev needs it
        gnumake # ponytail: moved from general
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.general.enable (with pkgs; [
        firefox
        chromium
        vivaldi
        vlc
        mpv
        yt-dlp
        ffmpeg
        pkgs.unstable.discord # ponytail: stable lags — single unstable package keeps every host fresh
        joplin-desktop
        onlyoffice-desktopeditors
        libreoffice-fresh
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
        heroic
        mangohud # ponytail: keep mangohud, drop goverlay/vkbasalt/vulkan-tools/cartridges
        protonup-qt
        (pkgs.unstable.bottles.override { removeWarningPopup = true; }) # ponytail: bottles follows the discord pattern — single unstable package keeps every host fresh; .override is correct because `with pkgs;` shadows `bottles` with the stable fixed-point function — fully-qualifying with `pkgs.unstable.bottles` is required
      ]))
      (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
        dbeaver-bin
        remmina
        filezilla
        gnumake # ponytail: work needs make even without dev group
      ]))
    ];
  };
}
