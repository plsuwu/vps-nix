{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.telemetry.alloy;
in
{
  options.services.telemetry.alloy = {
    enable = lib.mkEnableOption "alloy collection service";

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = ./configs/config.alloy;
    };
  };

  config = lib.mkIf cfg.enable {
    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:12345"
        "--disable-reporting"
      ];
    };

    environment.etc."alloy/config.alloy".source = cfg.configFile;
  };
}
