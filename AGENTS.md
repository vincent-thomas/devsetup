# Repo Context for Agents

## Overview

This is a **Nix-based dev environment setup** for `vincent-thomas/devsetup`. The repo manages personal development tooling configuration declaratively through Nix, producing a wrapped environment (symlinked as `./result`).

## Key Structural Patterns

- **Nix-driven config management**: All tool configs are defined in Nix files and rendered into static config files. The `flake.nix` builds the full dev environment.
- **Configs live under top-level directories**: Each tool has its own directory with a `config.nix` (source of truth) and `default.nix` (derivation builder).

## Git Config Management

Git configuration is **not** managed via `~/.gitconfig` or direct `.git/config` edits. Instead:

| File | Role |
|------|------|
| `git/config.nix` | **Source of truth** — Nix string containing the gitconfig content, with `${...}` interpolation for Nix-managed values (e.g., SSH path, secrets). The Nix build (`flake.nix`) passes this through `git/default.nix` to produce the wrapped git. |
| `git/default.nix` | Build derivation that wraps `git` with `GIT_CONFIG_GLOBAL` pointing to the managed config |
| `.git/config` | Low-level repo config (remotes, branches) — **do not** add aliases here |

**Convention**: When adding git aliases, update `git/config.nix` (unquoted value format, matching existing aliases).

### Git alias format

In `git/config.nix` (Nix string): `sameas = !f() { ... }; f`

## Other Managed Tools

The same Nix pattern applies to:
- `bash/` — bash configuration
- `cargo/` — Rust/Cargo config
- `secrets/` — encrypted secrets (managed via sops)
- `ssh/` — SSH config
- `tmux/` — tmux config

## Commands Policy

The Pi agent has restricted shell access. `git config` and `cd` are banned. Use `write`/`edit` tools for file changes.
