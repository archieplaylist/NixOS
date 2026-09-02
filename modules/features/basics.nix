# Fundamentals for every host: locale, kernel, nix-ld, printing, fonts, etc.
{ ... }: {
  config.nixos.modules.base = { config, lib, pkgs, ... }: {
    config = {
      networking.hostName = config.mySystem.hostname;
      system.stateVersion = "26.05";

      i18n.defaultLocale = "en_US.UTF-8";
      i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
      time.timeZone = "Asia/Jakarta";

      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;
      nixpkgs.config.allowUnfree = true;

      # LocalSend (flatpak) needs TCP+UDP 53317
      networking.firewall = {
        enable = true;
        allowPing = true;
        allowedTCPPorts = [ 53317 ];
        allowedUDPPorts = [ 53317 ];
      };

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        nssmdns6 = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
        };
      };

      services.printing = {
        enable = lib.mkDefault true;
        drivers = [ pkgs.gutenprint ];
      };
      services.system-config-printer.enable = lib.mkDefault true;

      boot.binfmt.registrations.appimage = {
        wrapInterpreterInShell = false;
        interpreter = "${pkgs.appimage-run}";
        recognitionType = "magic";
        offset = 0;
        magicOrExtension = ''\x7fELF....AI\x02'';
      };

      hardware.enableRedistributableFirmware = lib.mkDefault true;

      fonts.packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
      ];
    };
  };
}
