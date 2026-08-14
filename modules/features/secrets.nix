# sops-nix secrets. Contributes a NixOS module to the `base` slot, gated on
# `mySystem.enableSops`. Until secrets/secrets.yaml exists (created by setup.sh
# or `sops`), nothing is wired up so `nix flake check` stays green on a fresh
# clone.
{ ... }: {
  config.nixos.modules.base = { config, lib, ... }: {
    config = lib.mkIf (config.mySystem.enableSops && builtins.pathExists ../../secrets/secrets.yaml) {
      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;
        age = {
          # Absolute path: the sops systemd service runs as root ($HOME would
          # be non-deterministic). setup.sh writes the key here when run as root.
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
  };
}
