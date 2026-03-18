{
  config,
  lib,
  pkgs,
  system,
  piss-fan,
  ...
}:
let
  cfg = config.services.piss-fan;
in
{
  options.services.piss-fan = {
    client = {
      enable = lib.mkEnableOption "piss fan client";

      port = lib.mkOption {
        type = lib.types.port;
        default = 3002;
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = piss-fan.packages.${system}.client;
      };

      environmentFile = lib.mkOption {
        type = lib.types.path;
      };
    };
  };

  config = lib.mkIf cfg.client.enable {
    systemd.services.piss-fan-client = {
      description = "pissfan client service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        HOST = cfg.client.host;
        PORT = toString cfg.client.port;
        NODE_ENV = "production";
        PUBLIC_NODE_ENV = "production";
      };

      serviceConfig =
        let
          # preload = "/var/lib/piss-fan-client/build/server/instrumentation.server.js";
          index = "/var/lib/piss-fan-client/build/index.js";
        in
        {
          Type = "simple";
          DynamicUser = true;
          StateDirectory = "piss-fan-client";
          WorkingDirectory = "/var/lib/piss-fan-client";
          ExecStartPre = "${pkgs.coreutils}/bin/cp -rL --no-preserve=mode ${cfg.client.package}/. /var/lib/piss-fan-client/";
          ExecStart = "${pkgs.nodejs}/bin/node ${index}";
          Restart = "always";
          RestartSec = 5;

          EnvironmentFile = cfg.client.environmentFile;

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ "/var/lib/piss-fan-client" ];
          ProtectHome = true;
          RestrictSUIDSGID = true;
        };
    };

  };
}
