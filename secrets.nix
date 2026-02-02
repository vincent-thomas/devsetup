{ pkgs }:
let
  # Secrets activation - one file per secret
  #
  # keyCommand: command that outputs the age private key to stdout
  #
  # Usage:
  #   secretsConfig = mkSecretsActivation {
  #     keyCommand = "op read op://vault/age-key/key";
  #     secrets = {
  #       api_key = { file = ./secrets/api_key; };
  #       db_password = { file = ./secrets/db_password; mode = "0600"; };
  #     };
  #   };
  #
  # Returns: {
  #   activate = <derivation>;
  #   path = "/etc/vt/secrets";
  #   secrets = { api_key = { path = "/etc/vt/secrets/api_key"; }; ... };
  # }
  mkSecretsActivation =
    {
      secrets,
      keyCommand,
      secretsPath ? "/etc/vt/secrets",
      defaultMode ? "0400",
    }:
    let
      secretNames = builtins.attrNames secrets;

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

          ${builtins.concatStringsSep "\n" (
            map (
              name:
              let
                s = secrets.${name};
                mode = s.mode or defaultMode;
              in
              ''
                sops --decrypt ${s.file} > "$SECRETS_PATH/${name}"
                chmod ${mode} "$SECRETS_PATH/${name}"
              ''
            ) secretNames
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
