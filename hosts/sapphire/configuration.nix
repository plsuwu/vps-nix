{
  modulesPath,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
    ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      ../../modules
    ];

  networking.hostName = "sapphire";
  time.timeZone = "Australia/Brisbane";

  age.secrets = {
    server-env = {
      file = ../../secrets/piss-fan-server-env.age;
    };
    client-env = {
      file = ../../secrets/piss-fan-client-env.age;
    };

    grafana = {
      file = ../../secrets/grafana.age;
      owner = "grafana";
      mode = "0400";
    };
  };

  services =
    let
      ageFiles = config.age.secrets;
    in
    {
      piss-fan = {
        # front end
        client = {
          enable = true;
          port = 3002;
          environmentFile = ageFiles.client-env.path;
        };

        # api
        server = {
          enable = true;
          environmentFile = ageFiles.server-env.path;
        };
      };

      plsuwu.enable = true;

      telemetry = {
        alloy.enable = true;
        prometheus.enable = true;

        tempo = {
          enable = true;
          bucketName = ../../secrets/gcp-bucket.age;
          serviceCredential = ../../secrets/gcp-service.age;
        };

        loki = {
          enable = true;
          bucketName = ../../secrets/gcp-bucket.age;
          serviceCredential = ../../secrets/gcp-service.age;
        };

        grafana = {
          enable = true;
          environmentFile = ageFiles.grafana.path;
        };
      };

      do-postgres = {
        enable = true;
        databases = [ "pissfan" ];
      };

      do-nginx.enable = true;
      do-redis.enable = true;

      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = false;
        };
      };

      fail2ban = {
        enable = true;
        maxretry = 3;
        bantime = "1h";
        bantime-increment.enable = true;
      };
    };

  environment.systemPackages = with pkgs; [
    btrfs-progs

    git
    neovim
    htop

    sqlx-cli
    openssl
  ];

  networking.firewall = {
    allowedTCPPorts = [
      22
      80
      443
    ];

    allowedUDPPorts = [ ];
    rejectPackets = false;
    logRefusedConnections = false;
  };

  networking.enableIPv6 = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";

  # fileSystems."/volume" = {
  #   device = "/dev/disk/by-uuid/bfee169a-74ae-4263-8157-00d7f1b718dc";
  #   fsType = "btrfs";
  #
  #   options = [
  #     "compress=zstd"
  #     "noatime"
  #   ];
  # };

  swapDevices = [
    {
      device = "/swapfile";
      size = 4 * 1024;
    }
  ];
}
