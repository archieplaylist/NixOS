{ config
, lib
, impermanence
, ...
}: {
  # NOTE: not yet functional. The hosts use a XFS label-root layout with no
  # /persist mount and no tmpfs root, so nothing is actually wiped or persisted.
  # See README "Impermanence"; wiring it up properly is out of scope.

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
