{ pkgs, config }:

let
  configFile = pkgs.writeText "gitconfig" config;
in
pkgs.stdenv.mkDerivation {
  pname = "vt-git";
  version = pkgs.git.version;

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/{config,bin}
    cp ${configFile} $out/config/gitconfig

    makeWrapper ${pkgs.git}/bin/git $out/bin/git \
      --set GIT_CONFIG_GLOBAL $out/config/gitconfig
  '';
}
