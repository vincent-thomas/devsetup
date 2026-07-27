#!/bin/sh
set -eu

flake=${DEVSETUP_FLAKE:-github:vincent-thomas/devsetup}
installer=${DEVSETUP_NIX_INSTALLER:-https://install.determinate.systems/nix}

fail() {
  printf 'devsetup: %s\n' "$*" >&2
  exit 1
}

case "$(uname -s):$(uname -m)" in
  Linux:x86_64 | Linux:aarch64 | Linux:arm64 | Darwin:x86_64 | Darwin:arm64) ;;
  *) fail "unsupported platform: $(uname -s) $(uname -m)" ;;
esac

[ "$(id -u)" -ne 0 ] || fail "run this installer as your normal user, not root"

if ! command -v nix >/dev/null 2>&1; then
  command -v curl >/dev/null 2>&1 || fail "curl is required to install Nix"
  printf '%s\n' 'Installing Nix...'
  curl --proto '=https' --tlsv1.2 -fsSL "$installer" |
    sh -s -- install --no-confirm

  for nix_profile in \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    "$HOME/.nix-profile/etc/profile.d/nix.sh"
  do
    if [ -f "$nix_profile" ]; then
      # shellcheck disable=SC1090
      . "$nix_profile"
      break
    fi
  done
fi

command -v nix >/dev/null 2>&1 ||
  fail "Nix was installed but is not available in this shell; start a new shell and rerun"

# Removing an absent element is harmless. Replacing the named element makes
# rerunning this installer both an install and an update operation.
nix profile remove devsetup >/dev/null 2>&1 || true
nix profile install "${flake}#devsetup"

printf '\n%s\n' 'devsetup is installed. Start a new shell to use the tools.'
