{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.telemetry.loki;
in
{
  options.services.telemetry.loki = {
    enable = lib.mkEnableOption "grafana loki";

    bucketName = lib.mkOption {
      type = lib.types.path;
      default = ../../secrets/gcp-bucket.age;
    };

    serviceCredential = lib.mkOption {
      type = lib.types.path;
      default = ../../secrets/gcp-service.age;
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.gcp-users = {
      members = [ "loki" ];
    };

    age.secrets = {
      gcp-storage-loki = {
        file = cfg.bucketName;
        owner = "root";
        group = "gcp-users";
        mode = "0440";
      };

      gcp-credential-loki = {
        file = cfg.serviceCredential;
        owner = "root";
        group = "gcp-users";
        mode = "0440";
      };
    };

    systemd.services.loki = {
      environment = {
        GOOGLE_APPLICATION_CREDENTIALS = config.age.secrets.gcp-credential-loki.path;
      };
      serviceConfig.EnvironmentFile = [
        config.age.secrets.gcp-storage-loki.path
      ];
    };

    services.loki = {
      enable = true;
      extraFlags = [ "-config.expand-env=true" ];

      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = 3100;
          grpc_listen_port = 9096;

          log_level = "info";
          grpc_server_max_concurrent_streams = 1000;
        };

        common = {
          instance_addr = "127.0.0.1";
          path_prefix = "/var/lib/loki";
          replication_factor = 1;
          ring.kvstore.store = "memberlist";
        };

        schema_config.configs = [
          {
            from = "2020-10-24";
            store = "tsdb";
            object_store = "gcs";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        storage_config = {
          gcs = {
            bucket_name = "\${GCS_BUCKET_LOKI}";
          };
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
          };
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          retention_enabled = true;
          delete_request_store = "gcs";
        };

        limits_config = {
          metric_aggregation_enabled = true;
          enable_multi_variant_queries = true;
          retention_period = "672h";
        };

        query_scheduler = {
          scheduler_ring.kvstore.store = "memberlist";
        };

        query_range.results_cache.cache = {
          embedded_cache = {
            enabled = true;
            max_size_mb = 100;
          };
        };

        pattern_ingester = {
          enabled = true;
          metric_aggregation.loki_address = "localhost:3100";
        };
        ruler.alertmanager_url = "http://localhost:9003";
        frontend.encoding = "protobuf";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/loki 0755 loki loki -"
      "d /var/lib/loki/chunks 0755 loki loki -"
      "d /var/lib/loki/tsdb-index 0755 loki loki -"
      "d /var/lib/loki/tsdb-cache 0755 loki loki -"
      "d /var/lib/loki/compactor 0755 loki loki -"
    ];
  };
}
