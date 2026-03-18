{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.telemetry.grafana;
in
{
  options.services.telemetry.grafana = {
    enable = lib.mkEnableOption "grafana web interface";

    environmentFile = lib.mkOption {
      type = lib.types.path;
    };

    admin_user = {
      type = lib.types.str;
      default = "admin";
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          domain = "grafana.rat.moe";
          root_url = "https://grafana.rat.moe/";
          serve_from_sub_path = false;
        };
        security = {
          # admin_user = cfg.admin_user;
          admin_password = "$__file{${toString cfg.environmentFile}}";
        };
      };

      provision = {
        datasources.settings = {
          apiVersion = 1;
          prune = true;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:9090";
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://localhost:3100";
            }
            {
              name = "Tempo";
              type = "tempo";
              url = "http://localhost:3200";
            }
          ];
        };
      };
    };
  };
}
