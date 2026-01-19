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

            rustPkgs = fenix.packages.${system}.stable.withComponents [
              "cargo"
              "rustc"
              "rust-src"
            ];

            runtimeInputs =
              (with pkgs; [
                jq
                curl
                fzf
                fd
                direnv
                starship
              ])
              ++ [
                inputs.vt-nvim.packages.${system}.default
                git
                rustPkgs
              ];

            bash = import ./bash {
              inherit pkgs runtimeInputs;
              configFile = ./bash/bashrc;
            };

            tmux = import ./tmux {
              inherit pkgs;
              shellBin = "${bash}/bin/bash";
            };
          in
          {
            inherit tmux bash git;
            default = pkgs.writeShellApplication {
              name = "vt-devenv";
              runtimeInputs = [ tmux ];
              text = ''
                exec tmux new-session -Asmain
              '';
            };

          };
      }
    );
}
