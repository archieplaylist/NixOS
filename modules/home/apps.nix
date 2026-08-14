# User packages. Each group is gated on the single source of truth:
# `mySystem.appGroups.<group>.enable` (see modules/features/mySystem.nix),
# read from the NixOS config via `osConfig`.
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    home.packages = lib.mkMerge [
      # Shell utilities (not gated; used everywhere).
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
        unzip
        unrar
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
        # Discord is not on the stable channel; pulled from nixpkgs-unstable
        # via the `pkgs.unstable` overlay (see modules/outputs.nix).
        joplin-desktop
        onlyoffice-desktopeditors
        libreoffice-fresh
        vscode
        pkgs.unstable.discord
      ]))
      # Gaming applications.
      (lib.mkIf osConfig.mySystem.appGroups.gaming.enable (with pkgs; [
        heroic
        cartridges
        vulkan-tools
        pkgs.unstable.mangohud
        pkgs.unstable.goverlay
      ]))
      # Work applications.
      (lib.mkIf osConfig.mySystem.appGroups.work.enable (with pkgs; [
        dbeaver-bin
        remmina
        pkgs.unstable.filezilla
      ]))
    ];
  };
}
