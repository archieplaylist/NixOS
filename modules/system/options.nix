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
      description = "Enable nix-community/impermanence (not yet functional — see README).";
    };
  };
}