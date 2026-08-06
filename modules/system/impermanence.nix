{ config
, lib
, impermanence
, ...
}: {
  options.mySystem = {
    enableImpermanence = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable nix-community/impermanence (stateless root, persistent /persist).";
    };
  };

  # imports must be static; the config below is gated by the option.
  imports = [ impermanence.nixosModules.impermanence ];

  config = lib.mkIf config.mySystem.enableImpermanence {
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/log"
      ];
    };

    # home-manager files live under the same /persist.
    home-manager.users.mario.persistence = {
      directories = [
        "Downloads"
        "Documents"
        "Pictures"
        ".ssh"
        ".config/gh"
        ".local/share/keyrings"
      ];
      files = [
        ".gitconfig"
        ".gitignore"
      ];
    };
  };
}
