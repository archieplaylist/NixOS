# fetch — animated 3D fetch tool (areofyl/fetch).
# Builds from source; wraps fastfetch + pciutils on PATH.
{ lib, stdenv, fetchFromGitHub, makeWrapper, fastfetch, pciutils }:

stdenv.mkDerivation (finalAttrs: {
  pname = "fetch";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "areofyl";
    repo = "fetch";
    rev = "v${finalAttrs.version}";
    hash = "sha256-YEHvV07d02SzYO+lGT0Q+NkVoQNqxapBZfh44NOf/cw=";
  };

  makeFlags = [ "PREFIX=${placeholder "out"}" ];
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/fetch \
      --prefix PATH : ${
        lib.makeBinPath ([ fastfetch ] ++ lib.optionals stdenv.hostPlatform.isLinux [ pciutils ])
      }
  '';

  meta = with lib; {
    description = "Animated 3D fetch tool that renders your distro logo as a spinning bas-relief";
    homepage = "https://github.com/areofyl/fetch";
    license = licenses.isc;
    mainProgram = "fetch";
    platforms = platforms.unix;
  };
})
