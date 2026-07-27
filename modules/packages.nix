{
  inputs,
  pkgs,
  system,
}:

let
  rust = inputs.fenix.packages.${system}.stable.withComponents [
    "cargo"
    "clippy"
    "rust-analyzer"
    "rust-src"
    "rustc"
    "rustfmt"
  ];
in
(with pkgs; [
  bacon
  bash
  bun
  cargo-nextest
  curl
  direnv
  fd
  fzf
  gh
  git
  jq
  lazygit
  mdbook
  neovim
  tmux
])
++ [ rust ]
