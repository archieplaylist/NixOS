{ stdenvNoCC, fetchFromGitHub, gettext, glib, gnome-shell, unzip }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gnome-shell-extension-simple-taskbar";
  version = "71";
  src = fetchFromGitHub {
    owner = "Sultech";
    repo = "simple-taskbar";
    rev = finalAttrs.version;
    hash = "sha256-5UgHQUU8UkCJm1HDYARr65AfNnIQAroE2el4KiabVew=";
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
})
