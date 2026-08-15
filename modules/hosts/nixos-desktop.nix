# nixos-desktop host: picks the `base`, `desktop`, `intel` and `uefi` feature
# slots and sets the per-host `mySystem` flags.
{ config, ... }: {
  config.nixos.hosts.nixos-desktop = {
    imports = [
      config.nixos.modules.base
      config.nixos.modules.desktop
      config.nixos.modules.intel
      config.nixos.modules.uefi
    ];

    mySystem.hostname = "nixdesks";
    mySystem.desktop = "gnome";
    mySystem.enableDesktop = true;
    mySystem.enableSSH = true;
    mySystem.enableDocker = true;
    mySystem.enableTailscale = true;
    mySystem.enableSops = true;
    mySystem.enableSmartd = true;

    # Declarative Flatpak apps (nix-flatpak; daemon + wiring live in desktop.nix).
    mySystem.flatpakApps = [
      "com.github.wwmm.easyeffects"
      "org.localsend.localsend_app"
      "it.mijorus.gearlever"
      "com.github.tchx84.Flatseal"
      "com.mattjakeman.ExtensionManager"
    ];

    # SSH password auth is disabled (see services.nix), so the keys below are
    # what actually grants access — add your real public keys here.
    mySystem.sshAuthorizedKeys = [ ];
  };
}
