# fastfetch — boxed layout from https://raw.githubusercontent.com/mc-724634/NixDotfiles/refs/heads/main/extras/fastfetch/config.jsonc
# Package installed in apps.nix; this module provides ~/.config/fastfetch/config.jsonc
_: {
  config.home.modules.mario = {
    xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch/config.jsonc;
  };
}
