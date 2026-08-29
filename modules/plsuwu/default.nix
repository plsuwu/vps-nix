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
    root = lib.mkOption {
      type = lib.types.str;
      default = "${plsuwu.packages.${system}.default}/dist";
    };
  };
}
