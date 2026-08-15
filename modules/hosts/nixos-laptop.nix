# nixos-laptop host: like the desktop host plus the `laptop` power-management
# slot, and no heavy development tooling.
{ config, ... }: {
  config.nixos.hosts.nixos-laptop = { pkgs, ... }: {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
      config.nixos.modules.laptop
    ];

    # Newest mainline kernel for the latest laptop hardware support
    # (overrides the channel-default kernel in basics.nix).
    boot.kernelPackages = pkgs.linuxPackages_latest;

    mySystem.hostname = "nixlappys";
    mySystem.enableDesktop = true;
    mySystem.enableLaptop = true;
    mySystem.enableSSH = false;
    mySystem.enableDocker = false;
    mySystem.enableTailscale = true;
    mySystem.enableSops = true;

    # Declarative Flatpak apps (nix-flatpak; daemon + wiring live in desktop.nix).
    mySystem.flatpakApps = [
      "com.github.wwmm.easyeffects"
      "org.localsend.localsend_app"
      "it.mijorus.gearlever"
      "com.github.tchx84.Flatseal"
      "com.mattjakeman.ExtensionManager"
    ];

    # If SSH is enabled on this host, put your real public keys here.
    mySystem.sshAuthorizedKeys = [ ];

    # Lighter host: no heavy development tooling.
    mySystem.appGroups.dev.enable = false;
  };
}
