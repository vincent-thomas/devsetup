# devsetup

A reproducible user-scoped development environment for Linux and macOS.
Packages come from one locked Nix flake, so the host distribution does not
determine tool versions.

## Install or update

```sh
curl -fsSL https://raw.githubusercontent.com/vincent-thomas/devsetup/main/install.sh | sh
```

The installer supports:

- x86-64 Linux
- ARM64 Linux
- Intel macOS
- Apple Silicon macOS

It installs Nix when necessary, then installs the `devsetup` profile into the
current user's Nix profile. Run the same command again to update. The base
profile does not require personal credentials or secrets.

The initial Nix installation may request administrator access. Subsequent
activations are user-scoped. Homebrew, `apt`, `dnf`, and `pacman` are not used.

## Test a checkout

```sh
DEVSETUP_FLAKE="path:$PWD" ./install.sh
```

## Current migration status

The portable profile installs the common command-line and Rust toolchain. The
legacy `nix run` tmux environment remains available while Git, shell, tmux, and
secret configuration are migrated to user-scoped activation.
