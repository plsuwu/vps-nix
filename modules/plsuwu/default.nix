{
  config,
  lib,
  pkgs,
  system,
  plsuwu,
  ...
}:
let
  cfg = config.services.plsuwu;
in
{
  options.services.plsuwu = {
    enable = lib.mkEnableOption ''plsuwu "SSG" webserver'';
    port = lib.mkOption {
      type = lib.types.port;
      default = 4321;
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = plsuwu.packages.${system}.default;
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.plsuwu = {
      description = ''plsuwu "SSG" webserver'';
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        HOST = cfg.host;
        PORT = toString cfg.port;
        NODE_ENV = "production";
        PUBLIC_NODE_ENV = "production";
      };

      serviceConfig =
        let
          index = "${cfg.package}/dist/server/entry.mjs";
        in
        {
          Type = "simple";
          DynamicUser = true;
          StateDirectory = "plsuwu";
          ExecStart = "${pkgs.nodejs}/bin/node ${index}";
          Restart = "always";
          RestartSec = 5;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          RestrictSUIDSGID = true;
        };
    };
  };
}
