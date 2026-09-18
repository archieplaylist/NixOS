# OpenCode v2 CLI — prebuilt single-file binary from the npm platform package.
# No npm at build or runtime; nodejs is not needed.
# Bump: `make update-opencode` (nix-update --flake opencode, follows npm dist-tag latest).
{ lib, pkgs }:

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "2.0.7";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-tvLryZvjh/OyYih2qHVeDj+HVJfWiVYrvfJdV7pzTss=";
  };

  sourceRoot = "package";
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/opencode $out/bin/opencode
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode 2 CLI - open source AI coding agent";
    homepage = "https://opencode.ai/v2";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
  };
})
