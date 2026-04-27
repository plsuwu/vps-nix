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
        "piss.fan" = {
          serverName = "piss.fan";
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

        "api.piss.fan" = {
          serverName = "api.piss.fan";
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

        "grafana.piss.fan" = {
          serverName = "grafana.piss.fan";
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

        "*.piss.fan" = {
          serverName = "*.piss.fan";

          extraConfig = ''
            set $subdomain "";
            if ($host ~* ^([^\.]+)\.piss\.fan$) {
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

        "plsuwu.com" = lib.mkIf config.services.plsuwu.enable {
          serverName = "plsuwu.com";
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            root = "${config.services.plsuwu.root}";
            index = "index.html";
          };
        };

        "_" = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
              extraParameters = [ "default_server" ];
            }
            {
              addr = "0.0.0.0";
              port = 443;
              ssl = true;
              extraParameters = [ "default_server" ];
            }
          ];
          serverName = "_";
          extraConfig = ''
            ssl_certificate /var/lib/snakeoil/snakeoil.crt;
            ssl_certificate_key /var/lib/snakeoil/snakeoil.key;

            return 444;
          '';
        };
      };
    };
  };
}
