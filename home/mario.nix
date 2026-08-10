{ config
, lib
, pkgs
, osConfig
, ...
}: {
  options = {
    myApps = {
      general = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable general-purpose applications (browsers, media).";
        };
      };
      gaming = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable gaming applications (MangoHud, gamescope, Heroic).";
        };
      };
      dev = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable development tooling (editors, languages, CLIs).";
        };
      };
      work = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable work applications (dbeaver-bin, filezilla, remmina).";
        };
      };
    };
  };

  config = {
    home = {
      username = "mario";
      homeDirectory = "/home/mario";
      stateVersion = "26.05";
    };

    # Explicit XDG layout: app config -> ~/.config, data -> ~/.local/share,
    # mutable state -> ~/.local/state, caches -> ~/.cache. Keeps the list of
    # things worth persisting short (3 dirs) instead of per-app paths.
    home.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_CACHE_HOME = "$HOME/.cache";
    };

    # Global git excludes — git reads $XDG_CONFIG_HOME/git/ignore
    # automatically, so these patterns apply to every repo on this machine
    # (unlike a ~/.gitignore, which git never consults unless the root of the
    # repo happens to be $HOME).
    xdg.configFile."git/ignore".text = ''
      result
      .direnv
      .cache
      node_modules
    '';

    # --- Shell ---------------------------------------------------------------
    programs.bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ls = "ls --color=auto";
        ll = "ls -lha";
        grep = "grep --color=auto";
      };
    };

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    # --- Tooling ---------------------------------------------------
    programs.git = {
      enable = true;
      settings = {
        user.name = "archieplaylist";
        user.email = "archieplaylist@users.noreply.github.com";
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
      };
    };

    # User-level packages.
    home.packages = lib.mkMerge [
      # Shell utilities (not gated; used everywhere).
      (with pkgs; [
        fzf
        bat
        eza
        python3
      ])
      # Development tooling. Disabled per host with
      # `home-manager.users.mario.myApps.dev.enable = false`.
      (lib.mkIf config.myApps.dev.enable (with pkgs; [
        vscode
        nodejs_24
        gh
        docker-compose
        jq
        yq
      ]))
      # General-purpose applications (browsers, media). Disabled per host with
      # `home-manager.users.mario.myApps.general.enable = false`.
      (lib.mkIf config.myApps.general.enable (with pkgs; [
        firefox
        chromium
        vivaldi
        vlc
        mpv
        joplin-desktop
        onlyoffice-desktopeditors
        libreoffice-fresh
      ]))
      # Gaming applications. Disabled per host with
      # `home-manager.users.mario.myApps.gaming.enable = false`.
      (lib.mkIf config.myApps.gaming.enable (with pkgs; [
        mangohud
        gamescope
        heroic
      ]))
      # Work applications. Enabled per host with
      # `home-manager.users.mario.myApps.work.enable = true`.
      (lib.mkIf config.myApps.work.enable (with pkgs; [
        dbeaver-bin
        filezilla
        remmina
      ]))
    ];

    # GNOME extensions are pinned by writing them directly into the user's
    # dconf database. The list itself lives in one place — the
    # mySystem.gnomeExtensions option (see modules/system/options.nix); the
    # system-level packages and GSettings defaults are derived from it in
    # desktop.nix. This dconf block is what GNOME actually reads per user.
    dconf = {
      enable = true;
      settings."org/gnome/shell" = {
        enabled-extensions = map (e: e.uuid) osConfig.mySystem.gnomeExtensions;
      };
      # User Themes extension: apply the WhiteSur-dark shell theme from
      # ~/.themes (linked below).
      settings."org/gnome/shell/extensions/user-theme" = {
        name = "WhiteSur-dark";
      };
    };

    # WhiteSur dark theme (GTK), icons and cursor. home-manager's `gtk` module
    # installs the packages, writes ~/.config/gtk-3.0/settings.ini, and sets
    # org.gnome.desktop.interface in dconf (including color-scheme=prefer-dark
    # for libadwaita apps).
    gtk = {
      enable = true;
      colorScheme = "dark";
      theme = {
        name = "WhiteSur-dark";
        package = pkgs.whitesur-gtk-theme;
      };
      iconTheme = {
        name = "WhiteSur-dark";
        package = pkgs.whiteSur-icon-theme;
      };
      cursorTheme = {
        name = "WhiteSur-cursors";
        package = pkgs.whiteSur-cursors;
      };
    };

    # Apply the WhiteSur-dark shell theme via the User Themes extension
    # (user-theme@gnome-shell-extensions.gcampax.github.com is in the enabled
    # extensions list above). The extension reads themes from ~/.themes and
    # ~/.local/share/themes, so link the GNOME Shell variant there.
    home.file.".themes/WhiteSur-dark" = {
      source = "${pkgs.whitesur-gtk-theme}/share/themes/WhiteSur-dark";
    };
  };
}
