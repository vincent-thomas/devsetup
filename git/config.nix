{ ssh, secrets }:

''
  [init]
    defaultBranch = main

  [url "git@github.com:"]
    insteadOf = https://github.com/

  [alias]
    st = status
    l = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative
    d = diff --word-diff --word-diff-regex='\\w+|[^[:space:]]'
    b = !git checkout $(git branch | tr -d ' *' | fzf)
    sameas = !f() { a=$(git rev-parse HEAD 2>/dev/null) && b=$(git rev-parse "$@" 2>/dev/null) && [ "$a" = "$b" ] && echo true || { echo false; false; }; }; f
    extract-commit = !f() { [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { echo "usage: git extract-commit <commit> <new-branch> [--push]" >&2; return 2; }; commit=$(git rev-parse --verify "$1^{commit}") || return; branch=$2; push=$3; [ -z "$push" ] || [ "$push" = "--push" ] || { echo "error: third argument must be --push" >&2; return 2; }; current=$(git symbolic-ref --quiet --short HEAD) || { echo "error: HEAD must be attached to a branch" >&2; return 1; }; git merge-base --is-ancestor "$commit" HEAD || { echo "error: commit must belong to the current branch" >&2; return 1; }; parents=$(git show -s --format=%P "$commit") && set -- $parents && [ "$#" -eq 1 ] || { echo "error: commit must have exactly one parent" >&2; return 1; }; parent=$1; git check-ref-format --branch "$branch" >/dev/null || return; ! git show-ref --verify --quiet "refs/heads/$branch" || { echo "error: branch '$branch' already exists" >&2; return 1; }; git diff --quiet && git diff --cached --quiet || { echo "error: working tree has changes" >&2; return 1; }; if [ "$push" = "--push" ]; then git ls-remote --exit-code --heads origin "$branch" >/dev/null; remote_status=$?; if [ "$remote_status" -eq 0 ]; then echo "error: branch '$branch' already exists on origin" >&2; return 1; elif [ "$remote_status" -ne 2 ]; then return "$remote_status"; fi; fi; git switch -c "$branch" "$parent" && git cherry-pick "$commit" && git switch "$current" && git rebase --rebase-merges --onto "$parent" "$commit" "$current" && { [ "$push" != "--push" ] || git push --set-upstream origin "$branch"; }; }; f

  [commit]
    gpgsign = true

  [gpg]
    format = ssh

  [core]
    askpass = ""
    sshCommand = ${ssh}/bin/ssh

  [user]
    email = vincent@v-thomas.com
    name = Vincent Thomas
    signingkey = ${secrets."github_ssh_key.pem".path}
''
