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
    signingkey = ${secrets."main_ssh_key.pem".path}
''
