{ config
, lib
, ...
}: {
  # sops needs secrets/secrets.yaml (created by setup.sh or `sops`). Until it
  # exists, nothing is wired up so `nix flake check` stays green on a fresh clone.
  config = lib.mkIf (config.mySystem.enableSops && builtins.pathExists ../secrets/secrets.yaml) {
    sops = {
      defaultSopsFile = ../secrets/secrets.yaml;
      age = {
        # Absolute path: the sops systemd service runs as root ($HOME would
        # be non-deterministic). setup.sh writes the key here when run as root.
        # On hosts with enableImpermanence this path is persisted automatically
        # via the impermanence users.root entry (see impermanence.nix).
        keyFile = "/root/.config/sops/age/keys.txt";
        generateKey = true;
      };
      secrets = {
        # Example secret — replace with your own. Add the encrypted value with:
        #   sops secrets/secrets.yaml
        example-wifi = {
          mode = "0440";
          owner = config.users.users.mario.name;
        };
      };
    };
  };
}
