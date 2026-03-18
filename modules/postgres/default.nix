{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.do-postgres;
in
{
  options.services.do-postgres = {
    enable = lib.mkEnableOption "postgresql service";
    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "databases to create";
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            database = lib.mkOption {
              type = lib.types.str;
              description = "database to be owned by this user";
            };
          };
        }
      );

      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.pg-pass = {
      file = ../../secrets/pg-pass.age;
      owner = "postgres";
      group = "postgres";
      mode = "0400";
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      enableTCPIP = false; # use UNIX socket only
      settings = {
        log_connections = true;
        log_disconnections = true;
        log_statement = "ddl";

        password_encryption = "scram-sha-256";

        # max_connections = "40";
        # shared_buffers = "1GB";
        # effective_cache_size = "3GB";
        # maintenance_work_mem = "512MB";
        # checkpoint_completion_target = "0.9";
        # wal_buffers = "16MB";
        # default_statistics_target = "500";
        # random_page_cost = "1.1";
        # effective_io_concurrency = "200";
        # work_mem = "10922kB";
        # huge_pages = "off";
        # min_wal_size = "4GB";
        # max_wal_size = "16GB";
      };

      authentication = lib.mkForce ''
        # TYPE  DATABASE    USER          ADDRESS       METHOD
        local   all         postgres                    trust
        host    all         postgres      127.0.0.1/32  trust
        local   all         all                         scram-sha-256
      '';

      ensureDatabases = cfg.databases;
      ensureUsers = [
        {
          name = "pissfan";
          ensureDBOwnership = true;
        }
      ];

      initialScript = pkgs.writeText "init-sql" ''
        ALTER USER pissfan PASSWORD :'db_pass';
      '';
    };

    systemd.services.pg-setpass = {
      description = "set pgsql user passwords";
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        RemainAfterExit = true;
      };

      script = ''
        PASSWORD=$(cat ${config.age.secrets.pg-pass.path})
        ${config.services.postgresql.package}/bin/psql -d postgres -c \
          "ALTER USER pissfan PASSWORD '$PASSWORD';"
      '';
    };
  };
}
