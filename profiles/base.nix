args@{ pkgs, ... }:

(import ../modules/packages.nix args)
++ (import ../modules/configuration.nix { inherit pkgs; })
