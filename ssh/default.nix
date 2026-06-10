{ pkgs, config }:

pkgs.writeShellApplication {
  name = "ssh";
  runtimeInputs = with pkgs; [
    coreutils
    openssh
  ];
  text = ''
    config_file="$(mktemp)"

    cleanup() {
      rm -f "$config_file"
    }

    on_signal() {
      cleanup
      trap - EXIT INT TERM HUP
      kill -s "$1" "$$"
    }

    trap cleanup EXIT
    trap 'on_signal INT' INT
    trap 'on_signal TERM' TERM
    trap 'on_signal HUP' HUP

    cat > "$config_file" <<EOF
${config}
EOF

    ${pkgs.openssh}/bin/ssh -F "$config_file" "$@"
  '';
}
