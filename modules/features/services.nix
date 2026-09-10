# SSH/Docker/Tailscale/VirtualBox + base CLI tools (base slot)
_: {
  config.nixos.modules.base = { config, lib, pkgs, ... }: {
    config = {
      services = {
        # ponytail: password login on purpose (keys optional) — user password comes from /etc/hashed-password
        openssh = lib.mkIf config.mySystem.enableSSH {
          enable = true;
          settings = {
            PasswordAuthentication = true;
            PermitRootLogin = "no";
            KbdInteractiveAuthentication = false;
          };
        };

        tailscale = lib.mkIf config.mySystem.enableTailscale {
          enable = true;
        };

        smartd = lib.mkIf config.mySystem.enableSmartd {
          enable = true;
          autodetect = true;
        };
      };

      virtualisation.docker = lib.mkIf config.mySystem.enableDocker {
        enable = true;
        enableOnBoot = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      virtualisation.virtualbox = lib.mkIf config.mySystem.enableVirtualBox {
        host.enable = true;
      };

      environment.systemPackages = with pkgs; [
        curl
        wget
        ripgrep
        unzip
      ];
    };
  };
}
