let
  violet = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMpDYn/bA/+IL/X3yUHn2g3rlVx373oBuI4W8I7BxKne please@violet";
  sapphire = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwQP+xNQifDOswAl8O5JtBOl8e6/OjPvaCOcKWwJHmV root@nixos";
in
{
  "pg-pass.age".publicKeys = [
    violet
    sapphire
  ];
  "sapphire-ip.age".publicKeys = [
    violet
    sapphire
  ];
  "piss-fan-client-env.age".publicKeys = [
    violet
    sapphire
  ];
  "piss-fan-server-env.age".publicKeys = [
    violet
    sapphire
  ];
  "grafana.age".publicKeys = [
    violet
    sapphire
  ];
  "gcp-bucket.age".publicKeys = [
    violet
    sapphire
  ];
  "gcp-service.age".publicKeys = [
    violet
    sapphire
  ];
}
