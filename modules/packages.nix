{
  inputs,
  pkgs,
  system,
  ...
}:

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
  rustup
  tmux
])
++ [ inputs.vt-nvim.packages.${system}.default ]
