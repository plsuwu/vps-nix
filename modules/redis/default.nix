{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.do-redis;
in
{
  options.services.do-redis = {
    enable = lib.mkEnableOption "enable systemd-supervised redis server";

    configPath = lib.mkOption {
      type = lib.types.path;
      default = /var/lib/redis-pissfan-cache;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6380;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pissfan-cache = {
      description = "pissfan redis cache";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig =
        let
          conf = toString cfg.configPath;
          port = toString cfg.port;
        in
        {
          Type = "notify";
          StateDirectory = "redis-pissfan-cache";
          WorkingDirectory = "/var/lib/redis-pissfan-cache";
          ExecStart = "${pkgs.redis}/bin/redis-server ${conf} --port ${port} --supervised systemd --daemonize no";

          ExecStop = "${pkgs.redis}/bin/redis-cli shutdown";
          Restart = "always";
          RestartSec = 3;
        };
    };
  };
}
