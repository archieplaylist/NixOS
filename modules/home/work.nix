# work host (central8) aliases — keep host-specific hacks out of the shared primary home
_: {
  config.home.modules.primary = { lib, osConfig, ... }:
    lib.mkIf (osConfig.mySystem.hostname == "central8") {
      programs.bash.shellAliases.websvr-restart =
        "cd ~/Documents/test-folder/websvr && sudo systemctl restart docker && sleep 3 && sudo docker compose down && sleep 3 && sudo docker compose up -d";
    };
}
