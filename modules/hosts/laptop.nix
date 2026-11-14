# laptop — gnome (trimmed for 8 GB) + power-management
{ config, ... }: {
  config.nixos.hosts.laptop = { pkgs, lib, ... }: {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
      config.nixos.modules.laptop
    ];

    # latest kernel for newer laptop hardware — drop when stable suffices
    boot.kernelPackages = pkgs.linuxPackages_latest;

    mySystem.hostname = "nixlappys";
    mySystem.desktop = "gnome";
    mySystem.enableDesktop = true;
    mySystem.enableLaptop = true;
    mySystem.enableTailscale = true;
    mySystem.enableSmartd = true;
    mySystem.enableVirtManager = true;
    mySystem.enableWireshark = true;
    mySystem.enableSunshine = true;
    mySystem.enableMoonlight = true;

    mySystem.appGroups.browsers.enable = true;
    mySystem.appGroups.media.enable = true;
    mySystem.appGroups.office.enable = true;
    mySystem.appGroups.comms.enable = true;
    mySystem.appGroups.editor.enable = true;
    mySystem.appGroups.dev.enable = true;
    mySystem.appGroups.gaming.enable = true;
    mySystem.appGroups.ai.enable = true;

    # Host-global list in features/mySystem.nix ships blur-my-shell and
    # CoverflowAltTab; mkForce replaces it wholesale (it also drops the
    # gaming.nix mkAfter append, so gamemode is listed explicitly).
    mySystem.gnomeExtensions = lib.mkForce [
      { uuid = "appindicatorsupport@rgcjonas.gmail.com"; package = "appindicator"; }
      { uuid = "caffeine@patapon.info"; package = "caffeine"; }
      { uuid = "clipboard-indicator@tudmotu.com"; package = "clipboard-indicator"; }
      { uuid = "drive-menu@gnome-shell-extensions.gcampax.github.com"; package = "removable-drive-menu"; }
      { uuid = "just-perfection-desktop@just-perfection"; package = "just-perfection"; }
      { uuid = "simple-taskbar@sultech"; package = "simple-taskbar"; }
      { uuid = "user-theme@gnome-shell-extensions.gcampax.github.com"; package = "user-themes"; }
      { uuid = "tailscale-gnome-qs@tailscale-qs.github.io"; package = "tailscale-qs"; }
      { uuid = "gamemode@charlieq0137gmail.com"; package = "gamemode-shell-extension"; }
    ];

    # idle background work an 8 GB laptop doesn't need (no calendar/online
    # accounts used); desktop-manager/gnome.nix sets evolution-data-server
    # to true unconditionally, hence mkForce
    services.gnome.localsearch.enable = false;
    services.gnome.gnome-online-accounts.enable = false;
    services.gnome.evolution-data-server.enable = lib.mkForce false;
  };
}
