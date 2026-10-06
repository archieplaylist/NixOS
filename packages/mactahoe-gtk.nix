{ stdenvNoCC, fetchurl, xz }:

stdenvNoCC.mkDerivation {
  pname = "mactahoe-gtk-theme";
  version = "2026-09-10";
  src = fetchurl {
    url = "https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/1e45e19f510edb8cde18fa84d6cd5319f60b086b/release/MacTahoe-Dark.tar.xz";
    hash = "sha256-COgW5TUiR5VdHPpktErwru53z7xStStPTUvs9lDPXhU=";
  };
  nativeBuildInputs = [ xz ];
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out/share/themes/MacTahoe-Dark"
    cp -R . "$out/share/themes/MacTahoe-Dark"
  '';
}
