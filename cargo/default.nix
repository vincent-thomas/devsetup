{ pkgs, cargoBin, configFile, name, toolchain }:

pkgs.stdenv.mkDerivation {
  pname = name;
  version = "1.0.0";

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/{bin,config}
    cp ${configFile} $out/config/config.toml

    makeWrapper ${cargoBin} $out/bin/${name} \
      --add-flags "--config $out/config/config.toml" \
      --prefix PATH : ${pkgs.lib.makeBinPath [ toolchain ]}
  '';
}
