# User packages. Each group is gated on the single source of truth:
# `mySystem.appGroups.<group>.enable` (see modules/system/options.nix).
{ lib
, pkgs
, osConfig
, ...
}: {
  home.packages = lib.mkMerge [
    # Shell utilities (not gated; used everywhere).
    (with pkgs; [
      fzf
      bat
      eza
      python3
    ])
    # Development tooling.
    (lib.mkIf osConfig.mySystem.appGroups.dev.enable (with pkgs; [
      nodejs_24
      gh
      docker-compose
      jq
      yq
    ]))
    # General-purpose applications (browsers, media, editors).
    (lib.mkIf osConfig.mySystem.appGroups.general.enable (with pkgs; [
      firefox
      chromium
      vivaldi
      vlc
      mpv
      yt-dlp
      ffmpeg
      joplin-desktop
      onlyoffice-desktopeditors
      libreoffice-fresh
      vscode
    ]))
    # Gaming applications.
    (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
      mangohud
      gamescope
      heroic
    ]))
    # Work applications.
    (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
      dbeaver-bin
      filezilla
      remmina
    ]))
  ];
}