# primary home niri: validated config.kdl, noctalia wallpaper/app-themes,
# shared wallpaper, Bibata cursor + GTK font/icon theming, keyring, polkit agent.
# Alacritty unmanaged here — noctalia owns alacritty.toml (its hook can't write through a store symlink).
_: {
  config.home.modules.primary = { lib, pkgs, osConfig, ... }: lib.mkIf (osConfig.mySystem.desktop == "niri") {
    # unstable niri validates, same package that runs the session
    xdg.configFile."niri/config.kdl".source = pkgs.runCommand "niri-config-checked"
      {
        nativeBuildInputs = [ pkgs.unstable.niri ];
      } ''
      niri validate --config ${../assets/niri/config.kdl}
      cp ${../assets/niri/config.kdl} $out
    '';
    # noctalia merges every *.toml here; GUI settings.toml still wins
    xdg.configFile."noctalia/wallpaper.toml".text = ''
      [wallpaper.default]
      path = "/home/${osConfig.mySystem.username}/Pictures/Wallpapers/wallpaper.jpg"
    '';
    # builtin alacritty colors follow noctalia palette; alacritty.toml stays unmanaged so noctalia can own its include
    xdg.configFile."noctalia/app-themes.toml".text = ''
      [theme.templates]
      enable_builtin_templates = true
      builtin_ids = ["alacritty"]
    '';
    home.file."Pictures/Wallpapers/wallpaper.jpg".source = ../assets/wallpaper.jpg;
    # Bibata everywhere — cursor{} in config.kdl, GTK/XCURSOR shared via theming.nix
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
    };
    # ly PAM unlock is flaky — user daemon guarantees secrets+ssh socket
    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };
    home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
    # niri has no auth agent; without this keyring/polkit prompts hang
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "Polkit GNOME authentication agent";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
