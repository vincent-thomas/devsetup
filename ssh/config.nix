{ secrets }:

''
  Host *
    AddKeysToAgent no
    IdentitiesOnly yes
    IdentityAgent none

  Host github.com
    HostName github.com
    User git
    IdentityFile ${secrets."github_ssh_key.pem".path}

  Host codeberg.org
    HostName codeberg.org
    User git
    IdentityFile ${secrets."github_ssh_key.pem".path}

  Host dev
    HostName $(tr -d '\r\n' < ${secrets."work_dev_hostname".path})
    User ubuntu
    Port 22
    IdentityFile ${secrets."work_dev_shared_key.pem".path}
''
