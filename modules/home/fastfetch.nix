# fastfetch — boxed layout from https://raw.githubusercontent.com/mc-724634/NixDotfiles/refs/heads/main/extras/fastfetch/config.jsonc
# Package installed in apps.nix; this module provides ~/.config/fastfetch/config.jsonc
{ ... }: {
  config.home.modules.mario = {
    programs.fastfetch.enable = true;
    xdg.configFile."fastfetch/config.jsonc" = {
      source = ./fastfetch/config.jsonc;
      force = true; # ponytail: override programs.fastfetch.settings generated file
    };
  };
}
