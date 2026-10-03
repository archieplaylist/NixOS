{ stdenvNoCC, fetchFromGitHub, gettext, glib, gnome-shell, unzip }:

stdenvNoCC.mkDerivation {
  pname = "gnome-shell-extension-simple-taskbar";
  version = "66";
  src = fetchFromGitHub {
    owner = "Sultech";
    repo = "simple-taskbar";
    rev = "66";
    hash = "sha256-Rj7zI3xug6tzK+uB/RbsRTPmpkj5t44zJh+jxGw0HBM=";
  };
  nativeBuildInputs = [ gettext glib gnome-shell unzip ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    glib-compile-schemas --strict schemas
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
    runHook postInstall
  '';
}
