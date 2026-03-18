{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.do-nginx;
in
{
  options.services.do-nginx = {
    enable = lib.mkEnableOption "nginx service";
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      logError = "/var/log/nginx/error.log info";

      # recommendedOptimisation = true;
      recommendedGzipSettings = true;
      # recommendedProxySettings = true;
      # recommendedTlsSettings = true;

      commonHttpConfig =
        let
          realIpsFromList = lib.strings.concatMapStringsSep "\n" (
            x: "set_real_ip_from ${x};"
          );
          fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
          cfipv4 = fileToList (
            pkgs.fetchurl {
              url = "https://www.cloudflare.com/ips-v4";
              sha256 = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
            }
          );
          cfipv6 = fileToList (
            pkgs.fetchurl {
              url = "https://www.cloudflare.com/ips-v6";
              sha256 = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
            }
          );
        in
        ''
          ${realIpsFromList cfipv4}
          ${realIpsFromList cfipv6}
          real_ip_header CF-Connecting-IP;
        '';

      virtualHosts = {
        "rat.moe" = {
          serverName = "rat.moe";
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://localhost:3002";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };
        };

        "api.rat.moe" = {
          serverName = "api.rat.moe";
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://localhost:8080";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };

        };

        "grafana.rat.moe" = {
          serverName = "grafana.rat.moe";
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://localhost:3000";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };
        };

        "*.rat.moe" = {
          serverName = "*.rat.moe";

          extraConfig = ''
            set $subdomain "";
            if ($host ~* ^([^\.]+)\.rat\.moe$) {
              set $subdomain $1;
            }
          '';
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://localhost:3002";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;

              proxy_set_header X-Subdomain $subdomain;
            '';
          };
        };
      };
    };
  };
}
