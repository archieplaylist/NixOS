# SSH/Docker/Tailscale/VirtualBox + base CLI tools (base slot)
{ ... }: {
  config.nixos.modules.base = { config, lib, pkgs, ... }: {
    config = {
      warnings = lib.mkIf config.mySystem.enableSSH (
        lib.optionals (config.mySystem.sshAuthorizedKeys == [ ]) [
          "SSH is enabled but 'mySystem.sshAuthorizedKeys' is empty — nobody can log in over SSH."
        ]
      );

      services.openssh = lib.mkIf config.mySystem.enableSSH {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          KbdInteractiveAuthentication = false;
        };
      };

      virtualisation.docker = lib.mkIf config.mySystem.enableDocker {
        enable = true;
        enableOnBoot = true;
      };

      services.tailscale = lib.mkIf config.mySystem.enableTailscale {
        enable = true;
      };

      virtualisation.virtualbox = lib.mkIf config.mySystem.enableVirtualBox {
        host.enable = true;
      };

      services.smartd = lib.mkIf config.mySystem.enableSmartd {
        enable = true;
        autodetect = true;
      };

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
