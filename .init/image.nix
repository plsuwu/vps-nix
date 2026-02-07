{
  pkgs ? import <nixpkgs> { },
}:
let
  config = {
    imports = [ <nixpkgs/nixos/modules/virtualisation/digital-ocean-image.nix> ];
    virtualisation.digitalOceanImage.compressionMethod = "bzip2";
    environment.systemPackages = with pkgs; lib.mkMerge[[
      neovim
      git
      curl
    ]];
  };
in
(pkgs.nixos config).digitalOceanImage
