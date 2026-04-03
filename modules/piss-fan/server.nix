{
  config,
  lib,
  system,
  pkgs,
  piss-fan,
  ...
}:
let
  cfg = config.services.piss-fan.server;
in
{
  options.services.piss-fan.server = {
    enable = lib.mkEnableOption "piss fan API server";

    package = lib.mkOption {
      type = lib.types.package;
      default = piss-fan.packages.${system}.api;
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    # systemd.services.pg-run-migrations = {
    #   description = "run sqlx database migrations";
    #   after = [
    #     "postgresql.service"
    #     "pg-setpass.service"
    #   ];
    #   requires = [
    #     "postgresql.service"
    #     "pg-setpass.service"
    #   ];
    #   wantedBy = [ "multi-user.target" ];
    #
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     User = "postgres";
    #     EnvironmentFile = cfg.environmentFile;
    #
    #     ProtectHome = true;
    #     ProtectSystem = "strict";
    #     PrivateTmp = true;
    #     NoNewPrivileges = true;
    #   };
    #
    #   script = ''
    #     for i in $(seq 1 30); do
    #       ${pkgs.postgresql}/bin/pg_isready -q && break
    #       sleep 1
    #     done
    #
    #     DB_NAME="pissfan"
    #     if ${pkgs.postgresql}/bin/psql -tAc \
    #       "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" > /dev/null; then
    #       echo "db exists"
    #     else 
    #       ${pkgs.postgresql}/bin/createdb "$DB_NAME"
    #       echo "db created"
    #     fi
    #
    #     ${pkgs.sqlx-cli}/bin/sqlx migrate run --source ${cfg.package}/lib/migrations
    #   '';
    # };

    systemd.services.piss-fan-server = {
      description = "pissfan irc processing/api backend service";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "pissfan-cache.service"
        "alloy.service"
        "pg-run-migrations.service"
      ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;

        StateDirectory = "piss-fan-server";
        WorkingDirectory = "/var/lib/piss-fan-server";
        ExecStart = "${cfg.package}/bin/piss-fan-server";
        Restart = "always";
        RestartSec = 5;

        EnvironmentFile = cfg.environmentFile;

        NoNewPrivileges = true;
        ReadWritePaths = [ "/var/lib/piss-fan-server" ];
        ProtectSystem = "strict";
        ProtectHome = true;
        RestrictSUIDSGID = true;
      };
    };
  };
}
