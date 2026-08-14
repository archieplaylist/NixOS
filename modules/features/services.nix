# Services gated on per-host `mySystem` flags: SSH (hardened), Docker,
# Tailscale and VirtualBox, plus generic CLI tools for every host.
# Contributes a NixOS module to the `base` slot.
{ ... }: {
  config.nixos.modules.base = { config, lib, pkgs, ... }: {
    config = {
      # SSH is enabled but accepts no auth methods if no keys are configured
      # (PasswordAuthentication is off); surface it loudly instead of silently
      # locking the host out of SSH.
      warnings = lib.mkIf config.mySystem.enableSSH (
        lib.optionals (config.mySystem.sshAuthorizedKeys == [ ]) [
          "SSH is enabled but 'mySystem.sshAuthorizedKeys' is empty — nobody can log in over SSH."
        ]
      );

      # OpenSSH, hardened.
      services.openssh = lib.mkIf config.mySystem.enableSSH {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          KbdInteractiveAuthentication = false;
        };
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

      # VirtualBox host (builds the vboxdrv kernel module for the running kernel).
      virtualisation.virtualbox = lib.mkIf config.mySystem.enableVirtualBox {
        host.enable = true;
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
  };
}
