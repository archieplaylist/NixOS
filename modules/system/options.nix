{ lib, ... }: {
  options.mySystem = {
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Network hostname for the host.";
    };
    sshAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys for the primary user.";
    };
    enableDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the GNOME desktop environment.";
    };
    enableLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable laptop power management.";
    };
    enableSSH = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the OpenSSH server.";
    };
    enableDocker = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the Docker daemon.";
    };
    enableVirtualBox = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the VirtualBox host (with kernel modules).";
    };
    flatpakApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Flatpak app IDs to install declaratively via nix-flatpak.";
    };
    enableTailscale = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the Tailscale daemon.";
    };
    enableSops = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable sops-nix secret decryption.";
    };
    enableImpermanence = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable btrfs + impermanence: ephemeral / (rotated subvolume), persistent
        state in /persist, nix store in /nix. FRESH-INSTALL ONLY — the target
        disk must be formatted as btrfs with root/nix/persist subvolumes
        (setup.sh does this). Do not enable on a host that still uses the XFS
        layout: it cannot boot (there is no 'root' subvolume on XFS).
      '';
    };
  };
}