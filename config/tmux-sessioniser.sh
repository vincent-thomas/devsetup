set -euo pipefail

IFS=: read -r -a configured_roots <<< "${DEVSETUP_PROJECT_ROOTS:-$HOME/personal:$HOME/work}"
roots=()
for root in "${configured_roots[@]}"; do
  [[ -d "$root" ]] && roots+=("$root")
done

((${#roots[@]} > 0)) || {
  printf '%s\n' 'tmux-sessioniser: no project roots exist' >&2
  exit 1
}

if [[ $# -eq 1 ]]; then
  selected=$1
else
  selected=$(
    {
      fd --type d --max-depth 1 . "${roots[@]}"
      fd --type d --min-depth 2 --max-depth 2 . "${roots[@]}" |
        while IFS= read -r directory; do
          [[ -f "$directory/.git" ]] && printf '%s\n' "$directory"
        done
    } | awk 'NF && !seen[$0]++' | fzf
  )
fi

[[ -n "$selected" ]] || exit 0
[[ -d "$selected" ]] || {
  printf 'tmux-sessioniser: not a directory: %s\n' "$selected" >&2
  exit 1
}

session_name=$(basename "$selected" | tr . _)
if [[ -f "$selected/.git" ]]; then
  repository=$(basename "$(dirname "$selected")")
  session_name="${repository}_${session_name}"
fi

if [[ -z "${TMUX:-}" ]]; then
  exec tmux new-session -As "$session_name" -c "$selected"
fi

if ! tmux has-session -t="$session_name" 2>/dev/null; then
  tmux new-session -ds "$session_name" -c "$selected"
fi
exec tmux switch-client -t "$session_name"
