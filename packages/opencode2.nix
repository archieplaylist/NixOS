# OpenCode 2 CLI package (beta)
# Simple wrapper that runs npm install on first use
{ lib, pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "opencode2";
  version = "2.0.6";
  
  nativeBuildInputs = [ pkgs.makeWrapper ];
  
  buildCommand = ''
    mkdir -p $out/bin
    
    cat > $out/bin/opencode2 <<'EOF'
    #!/usr/bin/env bash
    set -e
    
    # Install @opencode/cli@beta via npm global
    if ! npm list -g @opencode/cli@beta &> /dev/null; then
      echo "Installing @opencode/cli@beta via npm..."
      npm install -g @opencode/cli@beta
    fi
    
    # Run opencode (v2 binary)
    exec opencode "$@"
    EOF
    
    chmod +x $out/bin/opencode2
    wrapProgram $out/bin/opencode2 --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs ]}
  '';
  
  meta = with lib; {
    description = "OpenCode 2 CLI - open source AI coding agent (beta)";
    homepage = "https://opencode.ai/v2";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "opencode2";
  };
}