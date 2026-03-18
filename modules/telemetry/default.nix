{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./alloy.nix
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
    ./tempo.nix
  ];
}
