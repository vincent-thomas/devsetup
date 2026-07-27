{
  inputs,
  pkgs,
  system,
  ...
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
{
  home.packages =
    (with pkgs; [
      bacon
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
    ++ [ rust ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.home-manager.enable = true;
}
