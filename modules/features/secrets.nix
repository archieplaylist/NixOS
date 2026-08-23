# sops-nix — gated on enableSops + file exists so fresh clone still passes `nix flake check`
{ ... }: {
  config.nixos.modules.base = { config, lib, ... }: {
    config = lib.mkIf (config.mySystem.enableSops && builtins.pathExists ../../secrets/secrets.yaml) {
      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;
        age = {
          keyFile = "/root/.config/sops/age/keys.txt";
          generateKey = true;
        };
        secrets.example-wifi = {
          mode = "0440";
          owner = config.users.users.mario.name;
        };
      };
    };
  };
}
