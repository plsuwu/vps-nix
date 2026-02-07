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
      ../../modules/postgres
    ];

  networking.hostName = "sapphire";

  services.do-postgres = {
    enable = true;
    databases = [ "peafan" ];
  };

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.11";

  swapDevices = [
    {
      device = "/swapfile";
      size = 4 * 1024;
    }
  ];
}
