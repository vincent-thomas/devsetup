{ pkgs }:
let
  # Secrets activation - one file per secret
  #
  # keyCommand: command that outputs the age private key to stdout
  #
  # Usage:
  #   secretsConfig = mkSecretsActivation {
  #     keyCommand = "op read op://vault/age-key/key";
  #     secretsDir = ./secrets;
  #   };
  #
  # Returns: {
  #   activate = <derivation>;
  #   path = "/etc/vt/secrets";
  #   secrets = { api_key = { path = "/etc/vt/secrets/api_key"; }; ... };
  # }
  mkSecretsActivation =
    {
      keyCommand,
      secretsDir ? ./secrets,
      # Runtime path used only to copy source file modes. Relative paths are
      # resolved from the directory where `nix run .#secrets` is invoked.
      sourceSecretsPath ? "./secrets",
      secretsPath ? "/etc/vt/secrets",
    }:
    let
      secretFiles = builtins.attrNames (pkgs.lib.filterAttrs (_: type: type == "regular") (builtins.readDir secretsDir));
      secretNames = secretFiles;

      activate = pkgs.writeShellApplication {
        name = "sops-activate";
        runtimeInputs = with pkgs; [
          sops
          coreutils
        ];
        text = ''
          SECRETS_PATH="${secretsPath}"

          sudo rm -rf "$SECRETS_PATH"
          sudo mkdir -p "$SECRETS_PATH"
          sudo chown "$USER" "$SECRETS_PATH"
          chmod 0700 "$SECRETS_PATH"

          export SOPS_AGE_KEY_CMD='${keyCommand}'

          source_mode() {
            if stat -f %Lp "$1" >/dev/null 2>&1; then
              stat -f %Lp "$1"
            else
              stat -c %a "$1"
            fi
          }

          ${builtins.concatStringsSep "\n" (
            map (file: ''
              sops --decrypt ${secretsDir}/${file} > "$SECRETS_PATH/${file}"
              chmod "$(source_mode '${sourceSecretsPath}/${file}')" "$SECRETS_PATH/${file}"
            '') secretFiles
          )}
        '';
      };

      secretsAttr = builtins.listToAttrs (
        map (name: {
          inherit name;
          value.path = "${secretsPath}/${name}";
        }) secretNames
      );

    in
    {
      inherit activate;
      path = secretsPath;
      secrets = secretsAttr;
    };

  # Sops wrapper that gets age key from command at runtime
  mkSopsWrapper =
    { keyCommand }:
    pkgs.writeShellApplication {
      name = "sops";
      runtimeInputs = with pkgs; [ sops ];
      text = ''
        export SOPS_AGE_KEY_CMD="${keyCommand}"
        exec ${pkgs.sops}/bin/sops "$@"
      '';
    };

in
{
  inherit mkSecretsActivation mkSopsWrapper;
}
