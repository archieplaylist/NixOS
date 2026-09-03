# nix-ld: dynamic linker for unpatched binaries (AppImages, vendor tarballs, etc.)
#
# Enables /lib64/ld-linux-x86-64.so.2 so non-Nix ELF binaries "just work".
# To temporarily disable: unset NIX_LD
# To find a missing library: nix run github:nix-community/nix-index-database -- lib/<name>.so
# Reference: https://wiki.nixos.org/wiki/Nix-ld
_: {
  config.nixos.modules.base = { pkgs, ... }: {
    config = {
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # ── Core system libraries ──
          stdenv.cc.cc.lib
          zlib
          zstd
          curl
          openssl
          attr
          libssh
          bzip2
          libxml2
          acl
          libsodium
          util-linux
          xz
          systemd
          glib

          # ── C/C++ runtime & dev ──
          gcc-unwrapped.lib
          elfutils
          icu
          krb5
          libsecret

          # ── X11 / display ──
          libxcomposite
          libxtst
          libxrandr
          libxext
          libX11
          libXfixes
          libxcb
          libxdamage
          libxshmfence
          libxxf86vm
          libxinerama
          libxcursor
          libxrender
          libXScrnSaver
          libXi
          libSM
          libICE
          libXt
          libXmu
          libXft

          # ── OpenGL / GPU / Vulkan ──
          libGL
          libGLU
          libva
          pipewire
          vulkan-loader
          libgbm
          libdrm
          mesa
          libvdpau

          # ── Audio ──
          alsa-lib
          libpulseaudio
          dbus
          dbus-glib
          libcanberra

          # ── Networking ──
          networkmanager

          # ── GTK / UI toolkits ──
          gtk2
          gtk3
          pango
          cairo
          atk
          gdk-pixbuf
          fontconfig
          freetype
          harfbuzz
          fribidi

          # ── Qt6 support ──
          libxcb-cursor
          xcbutilwm
          xcbutil
          xcbutilimage
          xcbutilkeysyms
          xcbutilrenderutil

          # ── Image / media codecs ──
          libpng
          libjpeg
          libtiff
          libwebp
          pixman
          ffmpeg

          # ── SDL family ──
          SDL
          SDL2
          SDL2_image
          SDL2_ttf
          SDL2_mixer
          SDL_image
          SDL_ttf
          SDL_mixer

          # ── Audio codecs / containers ──
          libvorbis
          libogg
          libtheora
          flac
          speex
          libmikmod
          libsamplerate
          freeglut
          glew_1_10

          # ── Misc shared libraries ──
          nspr
          nss
          libnotify
          cups
          libcap
          libusb1
          libidn
          libgcrypt
          libgpg-error
          libvpx
          librsvg
          libappindicator-gtk2
          libdbusmenu-gtk2
          libindicator-gtk2
          libcaca
          libudev0-shim
          pcre2

          # ── System / hardware ──
          pciutils
          zenity
          coreutils
          libxcrypt
          fuse
          e2fsprogs
          gmp
          expat
          libelf

          # ── AppImage / desktop integration ──
          gsettings-desktop-schemas
          libxcrypt-legacy

          # ── gdk-pixbuf SVG loader (needed for SVG thumbnails) ──
          (pkgs.runCommand "librsvg" {} ''
            mkdir -p $out/lib/gdk-pixbuf-2.0/2.10.0/loaders
            ln -s "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader_svg.so" "$out/lib/libpixbufloader-svg.so"
          '')
        ];
      };
    };
  };
}
