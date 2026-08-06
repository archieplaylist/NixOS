{ config
, lib
, ...
}: {
  options.mySystem = {
    enableSops = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable sops-nix secret decryption and the example secret.";
    };
  };

  # sops needs secrets/secrets.yaml (created by setup.sh or `sops`). Until it
  # exists, nothing is wired up so `nix flake check` stays green on a fresh clone.
  config = lib.mkIf (config.mySystem.enableSops && builtins.pathExists ../secrets/secrets.yaml) {
    sops = {
      defaultSopsFile = ../secrets/secrets.yaml;
      age = {
        keyFile = "$HOME/.config/sops/age/keys.txt";
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
