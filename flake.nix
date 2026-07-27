{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Retained until the portable profile adopts the external Neovim package.
    vt-nvim.url = "git+https://codeberg.org/vtho/nvim";
    vt-nvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    {
      overlays.default = final: _: {
        devsetup = self.packages.${final.system}.devsetup;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        portablePackages = import ./profiles/base.nix { inherit inputs pkgs system; };
        devsetup = pkgs.buildEnv {
          name = "devsetup";
          paths = portablePackages;
        };
      in
      {
        apps = {
          default = {
            type = "app";
            program = "${devsetup}/bin/devsetup";
          };
          activate = {
            type = "app";
            program = "${devsetup}/bin/devsetup";
          };
        };

        packages = {
          inherit devsetup;
          default = devsetup;
        };

        checks.devsetup = devsetup;

        devShells.default = pkgs.mkShell {
          packages = portablePackages;
        };
      }
    );
}
