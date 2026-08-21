# EasyEffects presets (JackHack96/EasyEffects-Presets) — vendored.
# Native easyeffects is installed system-wide in modules/features/audio.nix
# (environment.systemPackages). Presets are vendored at
# modules/home/assets/easyeffects/{output,irs} so no GitHub fetch is needed
# on rebuild. Update by re-running the vendor command in this file's header.
#
# To update to a newer upstream rev:
#   REV=<new-rev> DEST="$PWD/modules/home/assets/easyeffects" \
#   bash -c 'curl -fsSL https://github.com/JackHack96/EasyEffects-Presets/archive/$REV.tar.gz -o /tmp/ee.tar.gz && mkdir -p /tmp/ee-extract && tar -xzf /tmp/ee.tar.gz -C /tmp/ee-extract && SRC=$(find /tmp/ee-extract -maxdepth 1 -type d -name "EasyEffects-Presets-*") && rm -rf "$DEST" && mkdir -p "$DEST/output" "$DEST/irs" && cp "$SRC"/*.json "$DEST/output/" && cp -r "$SRC/irs/." "$DEST/irs/" && for f in "$DEST/output/Bass Boosted.json" "$DEST/output/Bass Enhancing + Perfect EQ.json"; do [ -f "$f" ] && sed -i "s|<PRESETS_DIRECTORY>|/home/mario/.config/easyeffects|g" "$f"; done && echo done'
{ ... }: {
  config.home.modules.mario = { lib, pkgs, osConfig, ... }: {
    # Only materialise when the desktop stack is enabled (matches audio.nix gate).
    xdg.configFile = lib.mkIf osConfig.mySystem.enableDesktop {
      "easyeffects/output".source = ./assets/easyeffects/output;
      "easyeffects/output".recursive = true;
      "easyeffects/irs".source = ./assets/easyeffects/irs;
      "easyeffects/irs".recursive = true;
    };

    # Autostart EasyEffects in the background on login (replaces Flatpak
    # autostart). Runs `easyeffects --gapplication-service` as a user
    # systemd service bound to the graphical session so it starts after
    # PipeWire and stops on logout.
    systemd.user.services.easyeffects = lib.mkIf osConfig.mySystem.enableDesktop {
      Unit = {
        Description = "EasyEffects audio effects for PipeWire";
        After = [
          "graphical-session.target"
          "pipewire.service"
          "pipewire-pulse.service"
        ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
