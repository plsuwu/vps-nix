{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.telemetry.prometheus;
in
{
  options.services.telemetry.prometheus = {
    enable = lib.mkEnableOption "grafana prometheus";
    scrapeInterval = {
      type = lib.types.nullOr lib.types.str;
      default = "15s";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      globalConfig.scrape_interval = "15s";
      extraFlags = [ "--web.enable-remote-write-receiver" ];

      scrapeConfigs = [
        {
          job_name = "alloy";
          static_configs = [
            {
              targets = [ "127.0.0.1:12345" ];
            }
          ];
        }
        {
          job_name = "tempo";
          static_configs = [
            {
              targets = [ "127.0.0.1:3200" ];
            }
          ];
        }
        {
          job_name = "loki";
          static_configs = [
            {
              targets = [ "127.0.0.1:3100" ];
            }
          ];
        }
      ];
    };
  };
}
