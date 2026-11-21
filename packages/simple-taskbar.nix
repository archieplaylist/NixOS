{ stdenvNoCC, fetchFromGitHub, gettext, glib, gnome-shell, unzip }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gnome-shell-extension-simple-taskbar";
  version = "7.4.1";
  src = fetchFromGitHub {
    owner = "Sultech";
    repo = "simple-taskbar";
    rev = finalAttrs.version;
    hash = "sha256-hKaIbGgBpXKwp3jDrcVxmP9z1O22NHiUV7e/ihEu/dI=";
  };
  nativeBuildInputs = [ gettext glib gnome-shell unzip ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    gnome-extensions pack --force \
      --extra-source=COPYING \
      --extra-source=ASSET-CREDITS.md \
      --extra-source=src \
      --extra-source=icons \
      --podir=po \
      --out-dir "$TMPDIR" .
    mkdir -p "$out/share/gnome-shell/extensions/simple-taskbar@sultech"
    unzip -q "$TMPDIR/simple-taskbar@sultech.shell-extension.zip" \
      -d "$out/share/gnome-shell/extensions/simple-taskbar@sultech"
    glib-compile-schemas --strict \
      "$out/share/gnome-shell/extensions/simple-taskbar@sultech/schemas"
    runHook postInstall
  '';
})
