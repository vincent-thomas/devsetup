{ pkgs, shellBin }:

let
  tmuxSessioniser = pkgs.writeShellApplication {
    name = "tmux-sessioniser";
    runtimeInputs = [
      pkgs.tmux
      pkgs.procps
    ];
    text = builtins.readFile ./tmux-sessioniser.sh;
  };

  # bind F run-shell "tmux neww ~/.config/scripts/tmux-list-sessions"
  tmuxConf = pkgs.writeText "tmux.conf" ''
    set -g default-terminal "screen-256color"
    set -as terminal-features ",xterm-256color:RGB"
    set -g default-shell "${shellBin}"

    set -g status-style "bg=default"

    set -g base-index 1
    set -g pane-base-index 1
    set -g renumber-windows on

    set -g status-right ""
    set -g status-left "#S"

    set -g automatic-rename on

    set -g mouse on
    set -g focus-events off
    setw -g aggressive-resize off
    setw -g clock-mode-style 24
    set -g escape-time 500
    set -g history-limit 5000

    bind f run-shell "tmux neww ${tmuxSessioniser}/bin/tmux-sessioniser"

    bind D detach
    bind d switch-client -t main

    # Use Alt-vim keys without prefix key to switch panes
    bind -n M-h select-pane -L
    bind -n M-j select-pane -D
    bind -n M-k select-pane -U
    bind -n M-l select-pane -R
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "vt-tmux";
  version = pkgs.tmux.version;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/tmux <<EOF
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.tmux}/bin/tmux -f ${tmuxConf} "\$@"
    EOF

    chmod +x $out/bin/tmux
  '';
}
