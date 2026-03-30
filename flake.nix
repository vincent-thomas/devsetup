{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";

    vt-nvim.url = "git+https://codeberg.org/vtho/nvim";
    vt-nvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      fenix,
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    let
      overlays = [
        (import rust-overlay)
      ];
    in
    {
      overlays.default = final: prev: {
        lio = self.packages.${final.system}.default;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        secretsLib = import ./secrets.nix { inherit pkgs; };

        # Command that outputs age private key - customize this
        keyCommand = "op item get jsjutcwq77jcm4qvjn6tg3nxly --field password --reveal";

        mySecrets = secretsLib.mkSecretsActivation {
          inherit keyCommand;
          secrets = {
            github_ssh_key = {
              file = ./secrets/github_ssh_key.pem;
              mode = "0600";
            };
            main_ssh_key = {
              file = ./secrets/main_ssh_key.pem;
              mode = "0600";
            };

            work_devbox_ssh_key = {
              file = ./secrets/work_devbox_ssh_key.pem;
              mode = "0600";
            };
          };
        };
      in
      rec {
        apps.default = {
          type = "program";
          program = "${packages.default}/bin/vt-devenv";
        };
        packages =
          let
            git = import ./git {
              inherit pkgs;
              configFile = ./git/gitconfig;
            };

            rustPkgs = fenix.packages.${system}.fromToolchainFile {
              file = ./rust-toolchain.toml;
              sha256 = "sha256-zC8E38iDVJ1oPIzCqTk/Ujo9+9kx9dXq7wAwPMpkpg0=";
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
                ])
                ++ [
                  inputs.vt-nvim.packages.${system}.default
                  git
                  rustPkgs
                ];
              secrets = mySecrets.secrets;
            };

            tmux = import ./tmux {
              inherit pkgs;
              shellBin = "${bash}/bin/bash";
            };

          in
          {
            inherit
              tmux
              bash
              git
              ;
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
            (secretsLib.mkSopsWrapper { inherit keyCommand; })
            pkgs.age
          ];
        };
      }
    );
}
