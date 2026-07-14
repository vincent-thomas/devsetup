{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vt-nvim.url = "git+https://codeberg.org/vtho/nvim";
    vt-nvim.inputs.nixpkgs.follows = "nixpkgs";

    # vt-pi.url = "github:vincent-thomas/lord-of-the-diffs";
    # vt-pi.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      fenix,
      nixpkgs,
      flake-utils,
      ...
    }:
    {
      overlays.default = final: prev: {
        lio = self.packages.${final.system}.default;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        fenixPkgs = fenix.packages.${system};

        secretsLib = import ./secrets.nix { inherit pkgs; };

        # Command that outputs age private key - customize this
        keyCommand = "op item get jsjutcwq77jcm4qvjn6tg3nxly --field password --reveal";

        mySecrets = secretsLib.mkSecretsActivation {
          inherit keyCommand;
          secretsDir = ./secrets;
        };
        mySops = secretsLib.mkSopsWrapper { inherit keyCommand; };
      in
      rec {
        apps.default = {
          type = "program";
          program = "${packages.default}/bin/vt-devenv";
        };
        packages =
          let
            ssh = import ./ssh {
              inherit pkgs;
              config = import ./ssh/config.nix { secrets = mySecrets.secrets; };
            };

            git = import ./git {
              inherit pkgs;
              config = import ./git/config.nix {
                inherit ssh;
                secrets = mySecrets.secrets;
              };
            };

            cargoConfigFile = ./cargo/config.toml;

            rustTargets = [
              "x86_64-unknown-linux-musl"
              "x86_64-unknown-linux-gnu"
            ];

            rustStableSpec = {
              channel = "1.94.0";
              sha256 = "1vlqg3lypl5qbn25f47qg3irq2r3jm9fkgg6pqwxa0bfygg7g8da";
            };

            rustNightlySpec = {
              channel = "nightly";
              date = "2026-03-07";
              sha256 = "1cr38gascmd6ywp4x7gh433c5fry5lsljf2sir4vpz9cqfkpw9fq";
            };

            mkRustToolchain =
              {
                name,
                source,
                toolchainSpec,
                hostComponents,
              }:
              pkgs.symlinkJoin {
                inherit name;
                paths = [
                  (source.withComponents hostComponents)
                ]
                ++ map (target: (fenixPkgs.targets.${target}.toolchainOf toolchainSpec)."rust-std") rustTargets;
              };

            rustStable = fenixPkgs.toolchainOf rustStableSpec;
            rustNightly = fenixPkgs.toolchainOf rustNightlySpec;

            rustStablePkgs = mkRustToolchain {
              name = "rust-stable";
              source = rustStable;
              toolchainSpec = rustStableSpec;
              hostComponents = [
                "rustc"
                "rust-src"
                "rustfmt"
                "clippy"
                "rust-analyzer"
              ];
            };

            rustNightlyPkgs = mkRustToolchain {
              name = "rust-nightly";
              source = rustNightly;
              toolchainSpec = rustNightlySpec;
              hostComponents = [
                "rustc"
                "rust-src"
                "rustfmt"
                "clippy"
                "miri"
              ];
            };

            cargo-stable = import ./cargo {
              inherit pkgs;
              cargoBin = "${rustStable.cargo}/bin/cargo";
              configFile = cargoConfigFile;
              name = "cargo";
              toolchain = rustStablePkgs;
            };

            cargo-nightly = import ./cargo {
              inherit pkgs;
              cargoBin = "${rustNightly.cargo}/bin/cargo";
              configFile = cargoConfigFile;
              name = "cargo-nightly";
              toolchain = rustNightlyPkgs;
            };

            bash = import ./bash {
              inherit pkgs;
              runtimeInputs =
                (with pkgs; [
                  jq
                  curl
                  fzf
                  fd
                  direnv
                  bacon
                  cargo-nextest
                  gh
                  mdbook
                  bun

                  # for rustc target suffix "-musl"
                  pkgsStatic.stdenv.cc
                ])
                ++ [
                  inputs.vt-nvim.packages.${system}.default
                  # inputs.vt-pi.packages.${system}.default
                  git
                  ssh
                  cargo-stable
                  cargo-nightly
                  rustStablePkgs
                ];
            };

            tmux = import ./tmux {
              inherit pkgs;
              shellBin = "${bash}/bin/bash";
            };

          in
          {
            secrets = mySecrets.activate;
            default = pkgs.writeShellApplication {
              name = "vt-devenv";
              runtimeInputs = [ tmux ];
              text = ''
                exec tmux new-session -Asmain
              '';
            };

          };

        devShells.default = pkgs.mkShell {
          packages = [
            mySops
            pkgs.age
          ];
        };
      }
    );
}
