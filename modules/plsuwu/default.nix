{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.plsuwu;
in
{
  options.services.plsuwu = {
    enable = lib.mkEnableOption "plsuwu webservice";

    root = lib.mkOption {
      type = lib.types.package;
      default = pkgs.writeTextDir "index.html" (builtins.readFile ./index.html);
    };
  };

  config = lib.mkIf cfg.enable { };
}
