#!/usr/bin/env bash

set -euo pipefail

DIRS=(
  "$HOME/personal"
  "$HOME/hdr"
  "$HOME/filen/Obsidian"
)

if [[ $# -eq 1 ]]; then
    selected=$1
else
    # Get depth 1 directories (regular repos)
    regular_dirs=$(fd . "${DIRS[@]}" --full-path --max-depth 1)

    # Get depth 2 directories that are worktrees (contain .git file)
    worktrees=$(fd . "${DIRS[@]}" --full-path --min-depth 2 --max-depth 2 | while read -r dir; do
        if [[ -f "$dir/.git" ]]; then
            echo "$dir"
        fi
    done)

    selected=$(echo -e "${regular_dirs}\n${worktrees}" | grep -v "^$" | fzf)
fi

if [[ -z "$selected" ]]; then
    exit 0
fi

# Get session name: for worktrees, include repo and branch; for regular repos, just repo name
if [[ -f "$selected/.git" ]]; then
    # This is a worktree - get branch name and repo name
    repo_name=$(basename "$(dirname "$selected")")
    branch_name=$(basename "$selected" | tr . _)
    selected_name="${repo_name}_${branch_name}"
else
    # Regular repo
    selected_name=$(basename "$selected" | tr . _)
fi
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z "$tmux_running" ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"
