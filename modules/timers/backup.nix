{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.services.timers.backup;
  script = ''
    set -euo 
    ${pkgs.coreutils}/bin/echo "--------------------------------"
    ${pkgs.coreutils}/bin/echo "[$(date)]  START: backup job"
    ${pkgs.coreutils}/bin/echo "[$(date)]  run user: $(whoami)"

    TIMESTAMP=$(date +%Y%m%d-%s)
    FILEPATH="/var/lib/localbackup/${cfg.targetDBName}/$TIMESTAMP.sql"

    ${pkgs.coreutils}/bin/echo "[$(date)] -> dump db state to file:"
    ${pkgs.coreutils}/bin/echo "[$(date)]    * '$FILEPATH'"

    # run pg_dump to save DB content locally (likely into /var/lib/localbackup/<db_name>)
    ${config.services.do-postgres.package}/bin/pg_dump    \
      -U "postgres" -Fc                                   \
      -d "${cfg.targetDBName}"                            \
      -f "/var/lib/localbackup/${cfg.targetDBName}/$TIMESTAMP.sql"

    ${pkgs.coreutils}/bin/echo "[$(date)] -> copying to gcs:"

    # copy to GCS bucket
    # NOTE: we are just hardcoding to the `postgres` user/directory here for now
    ${pkgs.google-cloud-sdk}/bin/gcloud storage cp \
      "/var/lib/localbackup/${cfg.targetDBName}/$TIMESTAMP.sql" \
      "gs://$GCS_BUCKET_PG_BACKUPS/postgres"

    ${pkgs.coreutils}/bin/echo "[$(date)]  DONE: backup job"
    ${pkgs.coreutils}/bin/echo "--------------------------------"
  '';
in
{
  options.services.timers.backup = {
    enable = lib.mkEnableOption "systemd timer for running database backup";

    localPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/localbackup";
    };

    targetDBName = lib.mkOption {
      type = lib.types.str;
      default = "pissfan";
    };

    # bucketName = lib.mkOption {
    #   type = lib.types.path;
    # };
    #
    # serviceCredential = lib.mkOption {
    #   type = lib.types.path;
    # };

    unitName = lib.mkOption {
      type = lib.types.str;
      default = "pg-backup";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.timers."${cfg.unitName}" = {
      wantedBy = [ "timers.target" ];
      after = [ "postgresql.service" ];
      timerConfig = {
        Unit = "${cfg.unitName}.service";
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    environment.systemPackages = [
      pkgs.google-cloud-sdk
    ];

    systemd.services."${cfg.unitName}" = {
      inherit script;
      serviceConfig = {
        Environment = [
          "CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=${config.age.secrets.backup-service.path}"
        ];

        EnvironmentFile = [
          config.age.secrets.backup-bucket.path
        ];

        Type = "oneshot";
        User = "postgres";
        Group = "postgres";
        ReadWritePaths = [ "/var/lib/localbackup/${cfg.targetDBName}" ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/localbackup 0755 postgres postgres -"
      "d /var/lib/localbackup/${cfg.targetDBName} 0755 postgres postgres -"
    ];
  };
}
