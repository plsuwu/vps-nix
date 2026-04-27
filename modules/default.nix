{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./telemetry
    ./postgres
    ./nginx
    ./redis

    ./piss-fan/client.nix
    ./piss-fan/server.nix
    ./plsuwu
  ];

  environment.systemPackages = [
    (
      pkgs.writeShellScriptBin "kill-pg-writers" ''
        #!/usr/bin/env bash

        SERVICES=("piss-fan-server")
        for service in "$SERVICES"; do
          systemctl stop "$service.service"
        done

        echo "killed pg connections"
      ''
    )
  ];
}
