{
  config,
  lib,
  pkgs,
  ...
}: {
  options.mySystem = {
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
  };

  config = {
    # OpenSSH, hardened.
    services.openssh = lib.mkIf config.mySystem.enableSSH {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
      hostKeys = [ ];
    };

    # Docker.
    virtualisation.docker = lib.mkIf config.mySystem.enableDocker {
      enable = true;
      enableOnBoot = true;
    };

    # Tailscale.
    services.tailscale = lib.mkIf config.mySystem.enableTailscale {
      enable = true;
    };

    # Generic command-line tools for all hosts.
    environment.systemPackages = with pkgs; [
      curl
      wget
      git
      htop
      ripgrep
      tree
      unzip
    ];
  };
}