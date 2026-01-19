{ pkgs, configFile, runtimeInputs ? [ ] }:

let
  runtimePath = pkgs.lib.makeBinPath runtimeInputs;
in
pkgs.stdenv.mkDerivation {
  pname = "vt-bash";
  version = pkgs.bash.version;

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/{config,bin}
    cp ${configFile} $out/config/.bashrc

    makeWrapper ${pkgs.bash}/bin/bash $out/bin/bash \
      --add-flags "--rcfile $out/config/.bashrc" \
      --prefix PATH : "${runtimePath}"
  '';
}
