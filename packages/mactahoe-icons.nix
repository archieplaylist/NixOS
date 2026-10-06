{ stdenvNoCC, fetchFromGitHub, bash, gtk3 }:

stdenvNoCC.mkDerivation {
  pname = "mactahoe-icon-theme";
  version = "2026-09-10";
  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-icon-theme";
    rev = "2026-09-10";
    hash = "sha256-NAahlBOYub0QlqkYStamoCbyWh+H5JG/iFm4Ws9EU3A=";
  };
  nativeBuildInputs = [ bash gtk3 ];
  dontBuild = true;
  installPhase = ''
    bash ./install.sh --dest "$out/share/icons" --name MacTahoe --theme default
  '';
}
