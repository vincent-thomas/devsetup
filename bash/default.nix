{
  pkgs,
  runtimeInputs ? [ ],
  secrets ? { },
}:

let
  runtimePath = pkgs.lib.makeBinPath runtimeInputs;

  bashrc = pkgs.writeText "bashrc" ''
    export HISTSIZE=50000
    export HISTFILESIZE=50000
    export HISTCONTROL=ignoreboth:erasedups
    shopt -s histappend

    eval "$(fzf --bash)"
    eval "$(direnv hook bash)"

    eval $(ssh-agent) > /dev/null
    ssh-add "${secrets.github_ssh_key.path}" 2> /dev/null
    ssh-add "${secrets.work_devbox_ssh_key.path}" 2> /dev/null

    alias nix="nix -L"
    alias rbd-image-clear="rbd list | xargs -n 1 -d '\n' rbd rm"
    alias docker-container-clear="docker container ls --format json | jq '.ID' -r | xargs -n 1 docker rm"
    alias docker-image-clear="docker image ls --format json | jq ".ID" -r | xargs -n 1 docker rmi"
    alias c="cargo"

    PS1='\[\e[38;5;183m\]\h\[\e[38;5;8m\] :: \[\e[38;5;14m\]\w\[\e[33m\] \$ \[\e[0m\]'

    # This has to be here otherwise op refuses to work for some reason.
    export OP_BIOMETRIC_UNLOCK_ENABLED=true
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "vt-bash";
  version = pkgs.bash.version;

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/{config,bin}
    cp ${bashrc} $out/config/.bashrc

    makeWrapper ${pkgs.bash}/bin/bash $out/bin/bash \
      --add-flags "--rcfile $out/config/.bashrc" \
      --prefix PATH : "${runtimePath}"
  '';
}
