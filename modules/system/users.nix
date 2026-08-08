{ config, lib, ... }: {
  config.users.users.mario = {
    isNormalUser = true;
    description = "Mario";
    extraGroups =
      [ "wheel" "video" "audio" ]
      ++ lib.optionals config.mySystem.enableDesktop [ "networkmanager" ]
      ++ lib.optionals config.mySystem.enableDocker [ "docker" ]
      ++ lib.optionals config.mySystem.enableVirtualBox [ "vboxusers" ];
    openssh.authorizedKeys.keys = config.mySystem.sshAuthorizedKeys;
    # Read at activation from the live filesystem (not the flake, so no git
    # interplay). setup.sh writes the hash here; if the file is missing the
    # activation only warns and the user has no password until one is set.
    hashedPasswordFile = "/etc/hashed-password";
  };
}