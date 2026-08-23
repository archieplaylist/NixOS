# User mario — hash from /etc/hashed-password (written by setup.sh, not stored in flake)
{ ... }: {
  config.nixos.modules.base = { config, lib, ... }: {
    config.users.users.mario = {
      isNormalUser = true;
      description = "Mario";
      extraGroups =
        [ "wheel" "video" "audio" ]
        ++ lib.optionals config.mySystem.enableDesktop [ "networkmanager" ]
        ++ lib.optionals config.mySystem.enableDocker [ "docker" ]
        ++ lib.optionals config.mySystem.enableVirtualBox [ "vboxusers" ]
        ++ lib.optionals config.mySystem.appGroups.gaming.enable [ "gamemode" ];
      openssh.authorizedKeys.keys = config.mySystem.sshAuthorizedKeys;
      hashedPasswordFile = "/etc/hashed-password";
    };
  };
}
