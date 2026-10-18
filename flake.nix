{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    agenix.url = "github:ryantm/agenix";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    piss-fan.url = "git+file:///home/please/src/pea-fan";
    plsuwu.url = "git+file:///home/please/src/plsuwu";
  };

  outputs =
    {
      self,
      nixpkgs,
      agenix,
      deploy-rs,
      piss-fan,
      plsuwu,
      ...
    }:
    let
      system = "x86_64-linux";
      overlays = import ./overlays;

      pkgs = import nixpkgs {
        inherit system overlays;
      };
    in
    {
      nixosConfigurations = {
        sapphire = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit piss-fan system plsuwu;
          };
          modules = [
            { nixpkgs.overlays = overlays; }
            ./hosts/sapphire/configuration.nix
            agenix.nixosModules.default
          ];
        };
      };

      deploy = {
        nodes.sapphire = {
          hostname = "PLACEHOLDER";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.sapphire;
          };
        };
      };

      checks = builtins.mapAttrs (
        system: deployLib: deployLib.deployChecks self.deploy
      ) deploy-rs.lib;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.jq
          pkgs.google-cloud-sdk
        ];
        packages = [
          deploy-rs.packages.${system}.default
          agenix.packages.${system}.default
          # piss-fan.packages.${system}.default
          # piss-fan.packages.${system}.client

          pkgs.age
          pkgs.ssh-to-age
          (pkgs.writeShellScriptBin "run-deploy" ''
            set -euo pipefail
            HOST_ADDR=$(age --decrypt -i ~/.ssh/id_ed25519 ./secrets/sapphire-ip.age)
            ${
              deploy-rs.packages.${system}.default
            }/bin/deploy ".#sapphire" --hostname "$HOST_ADDR" "$@" -- --impure
          '')
        ];
      };
    };
}
