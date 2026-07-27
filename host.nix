# Defaults used for repository checks. install.sh writes host.local.nix with
# the actual user, home directory, and selected profile.
{
  username = "devsetup";
  homeDirectory = "/home/devsetup";
  profile = "base";
}
