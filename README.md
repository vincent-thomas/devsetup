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
- Apple Silicon macOS

Intel macOS is not supported because current Nixpkgs has ended support for
`x86_64-darwin`. Using an obsolete package-set pin would not provide support
equivalent to the maintained Linux and Apple Silicon targets.

It installs Nix when necessary, then installs the `devsetup` profile into the
current user's Nix profile and activates Bash, Git, and tmux configuration. Run
the same command again to update. The base profile does not require personal
credentials or secrets.

Bash is the only supported login shell. The installer does not run `chsh`
because changing account state is host-specific and may require an interactive
password. If needed, change the account shell using the mechanism provided by
the host, then start a new Bash login shell.

The initial Nix installation may request administrator access. Subsequent
activations are user-scoped. Homebrew, `apt`, `dnf`, and `pacman` are not used.

## Test a checkout

```sh
DEVSETUP_FLAKE="path:$PWD" ./install.sh
```

## Management

```sh
devsetup activate
devsetup doctor
```

`activate` reconciles user-scoped Bash, Git, and tmux fragments. `doctor`
checks the login shell and core tool availability. Personal identity and
secrets remain deliberately separate from the credential-free base profile.
