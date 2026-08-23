# desktop host: picks the `base`, `desktop`, `intel` and `uefi` feature
# slots and sets the per-host `mySystem` flags.
{ config, lib, ... }: {
  config.nixos.hosts.desktop = {
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

    # Desktop gaming: no power-profiles-daemon on this host (laptop-only slot),
    # so pin the CPU to the performance governor instead of the default EPP.
    powerManagement.cpuFreqGovernor = "performance";

    # +Extension Manager on top of the base Flatpaks (mySystem.nix).
    mySystem.flatpakApps = lib.mkAfter [ "com.mattjakeman.ExtensionManager" ];

    # SSH password auth is disabled (see services.nix), so the keys below are
    # what actually grants access — add your real public keys here.
    mySystem.sshAuthorizedKeys = [ ];
  };
}
