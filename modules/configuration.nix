{ pkgs }:

let
  tmuxSessioniser = pkgs.writeShellApplication {
    name = "tmux-sessioniser";
    runtimeInputs = with pkgs; [
      fd
      fzf
      gawk
      tmux
    ];
    text = builtins.readFile ../config/tmux-sessioniser.sh;
  };

  devsetup = pkgs.writeShellApplication {
    name = "devsetup";
    runtimeInputs = with pkgs; [
      coreutils
      git
      gnugrep
    ];
    text = ''
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      devsetup_config="$config_home/devsetup"
      login_shell="''${SHELL:-}"

      append_once() {
        local line=$1
        local file=$2
        touch "$file"
        grep -Fqx "$line" "$file" || printf '\n%s\n' "$line" >> "$file"
      }

      activate() {
        mkdir -p "$devsetup_config"
        ln -sfn ${../config/bashrc} "$devsetup_config/bashrc"
        ln -sfn ${../config/gitconfig} "$devsetup_config/gitconfig"
        ln -sfn ${../config/tmux.conf} "$devsetup_config/tmux.conf"

        append_once ". \"$devsetup_config/bashrc\"" "$HOME/.bashrc"
        append_once "source-file \"$devsetup_config/tmux.conf\"" "$HOME/.tmux.conf"

        if ! git config --global --get-all include.path 2>/dev/null | grep -Fxq "$devsetup_config/gitconfig"; then
          git config --global --add include.path "$devsetup_config/gitconfig"
        fi

        if [[ ''${login_shell##*/} != bash ]]; then
          printf '%s\n' "devsetup: login shell is not Bash; run 'chsh -s /bin/bash' if appropriate for this host" >&2
        fi
      }

      doctor() {
        local failed=0
        local command
        for command in bash cargo direnv fd fzf git nvim tmux; do
          if ! command -v "$command" >/dev/null 2>&1; then
            printf 'missing: %s\n' "$command" >&2
            failed=1
          fi
        done
        [[ ''${login_shell##*/} == bash ]] || {
          printf 'login shell is %s, expected Bash\n' "''${login_shell:-unknown}" >&2
          failed=1
        }
        return "$failed"
      }

      case "''${1:-activate}" in
        activate) activate ;;
        doctor) doctor ;;
        *)
          printf '%s\n' 'usage: devsetup [activate|doctor]' >&2
          exit 2
          ;;
      esac
    '';
  };
in
[
  devsetup
  tmuxSessioniser
]
