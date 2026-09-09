# nix-ld: dynamic linker for unpatched binaries (AppImages, vendor tarballs, etc.)
#
# Enables /lib64/ld-linux-x86-64.so.2 so non-Nix ELF binaries "just work".
# To temporarily disable: unset NIX_LD
# To find a missing library: nix run github:nix-community/nix-index-database -- lib/<name>.so
# Reference: https://wiki.nixos.org/wiki/Nix-ld
#
# ponytail: minimal core only — add libs when ldd/nix-index says so, not just in case.
_: {
  config.nixos.modules.base = { pkgs, ... }: {
    config = {
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          zstd
          curl
          openssl
          glib
          gtk3
          fontconfig
          freetype
          alsa-lib
          libGL
          libX11
          nss
          nspr
          cups
          expat
        ];
      };
    };
  };
}
