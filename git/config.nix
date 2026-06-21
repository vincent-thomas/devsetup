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
