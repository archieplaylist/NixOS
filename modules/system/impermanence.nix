{ config
, lib
, impermanence
, ...
}: {
  # Functional impermanence on btrfs. Fresh-install only: the target disk must
  # be formatted as btrfs with root/nix/persist subvolumes (setup.sh creates
  # them). Do NOT enable on a host that still uses the XFS layout — it would
  # try to rotate a subvolume that doesn't exist and fail to boot.

  # imports must be static; the config below is gated by the option.
  imports = [ impermanence.nixosModules.impermanence ];

  config = lib.mkIf config.mySystem.enableImpermanence {
    # Rotate the root subvolume on every boot: current `root` is moved to
    # `old_roots/<timestamp>`, subvolumes older than 30 days are deleted, and a
    # fresh `root` is created. This is what makes "/" ephemeral while /nix
    # (store) and /persist (state) survive.
    boot.initrd.postResumeCommands = ''
      mkdir -p /btrfs_tmp
      mount /dev/disk/by-label/nixos-root /btrfs_tmp

      if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp="$(date --date="@$(stat -c %Y /btrfs_tmp/root)" '+%Y-%m-%-d_%H:%M:%S')"
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime "+30"); do
        delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';

    # System-level state that must survive the ephemeral root. Secrets are
    # NOT here — sops-nix owns those (see secrets.nix); only the age key
    # location is persisted so decryption works across boots.
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/NetworkManager/system-connections"
        # Host keys + sshd_config: whole-dir bind so the host keeps its SSH
        # identity across reboots.
        "/etc/ssh"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/log"
      ]
      ++ lib.optionals config.mySystem.enableDocker [ "/var/lib/docker" ]
      ++ lib.optionals config.mySystem.enableTailscale [ "/var/lib/tailscale" ]
      ++ lib.optionals config.mySystem.enableDesktop [ "/var/lib/flatpak" ];
      files = [
        "/etc/machine-id"
        "/etc/hashed-password"
      ];
      users.root = {
        directories = [
          { directory = ".config/sops/age"; mode = "0700"; }
        ];
      };
    };

    # home-manager state lives under the same /persist.
    #
    # API note: current impermanence moved the option to
    # `home.persistence."<path>"` *inside* the user config (auto-loaded by the
    # NixOS module above). The old `home-manager.users.<name>.persistence`
    # path and `allowOther` are removed — bind mounts make them unnecessary.
    #
    # Rule: persist only paths home-manager does NOT manage. Anything declared
    # with programs.* / home.file / xdg.configFile survives reboots via the nix
    # store, so listing it here (e.g. ".gitconfig" or the ".config/git/ignore"
    # exclude file) causes a manage/overwrite conflict. Secrets never go here
    # — sops-nix handles them.
    #
    # Caveat: ".config" contains home-manager-managed files too; a whole-dir
    # bind mount over them generally works, but if you hit conflicts, enumerate
    # the app subdirs instead (e.g. ".config/gh", ".config/gtk-3.0").
    home-manager.users.mario.home.persistence."/persist" = {
      directories = [
        "Downloads"
        "Documents"
        "Music"
        "Pictures"
        "Videos"
        # App-written config/state under the XDG layout (see home/mario.nix).
        # Includes dconf, ~/.config/gh, app caches that should survive.
        ".config"
        ".local/share"
        ".local/state"
        { directory = ".ssh"; mode = "0700"; }
        # XDG-unaware stragglers.
        ".mozilla" # Firefox profiles
        ".vscode" # VS Code extensions + state
      ];
    };
  };
}