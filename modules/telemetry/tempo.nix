{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.telemetry.tempo;
in
{
  options.services.telemetry.tempo = {

    enable = lib.mkEnableOption "grafana tempo";

    configFile = lib.mkOption {
      type = lib.types.path;
      default = ./configs/tempo.yaml;
    };

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
      members = [ "tempo" ];
    };

    age.secrets = {
      gcp-storage-tempo = {
        file = cfg.bucketName;
        owner = "root";
        group = "gcp-users";
        mode = "0440";
      };

      gcp-credential-tempo = {
        file = cfg.serviceCredential;
        owner = "root";
        group = "gcp-users";
        mode = "0440";
      };
    };

    systemd.services.tempo = {
      
      serviceConfig = {
        
        EnvironmentFile = [ config.age.secrets.gcp-storage-tempo.path ];
        Environment = [
          "GOOGLE_APPLICATION_CREDENTIALS=${config.age.secrets.gcp-credential-tempo.path}"
        ];
      };
    };

    services.tempo = {
      enable = true;
      extraFlags = [ "-config.expand-env=true" ];

      settings = {
        distributor.receivers.otlp.protocols = {
          grpc.endpoint = "0.0.0.0:4320";
          http.endpoint = "0.0.0.0:4321";
        };

        ingester.max_block_duration = "5m";
        compactor.compaction.block_retention = "336h";

        memberlist.bind_port = 7947;

        storage.trace = {
          backend = "gcs";
          gcs = {
            bucket_name = "\${GCS_BUCKET_TEMPO}";
          };
          wal.path = "/var/lib/tempo/wal";
        };

        query_frontend = {
          search = {
            duration_slo = "5s";
            throughput_bytes_slo = 1.073741824e+09;
          };

          trace_by_id.duration_slo = "5s";
        };

        metrics_generator = {
          registry.external_labels.source = "tempo";

          storage = {
            path = "/var/lib/tempo/generator/wal";
            remote_write = [
              { url = "http://localhost:9090/v1/write"; }
            ];
          };

          processor.span_metrics.dimensions = [
            "service.name"
            "span.name"
            "span.kind"
            "status.code"
          ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/tempo 0755 tempo tempo -"
      "d /var/lib/tempo/wal 0755 tempo tempo -"
      "d /var/lib/tempo/generator 0755 tempo tempo -"
      "d /var/lib/tempo/generator/wal 0755 tempo tempo -"
    ];
  };
}
