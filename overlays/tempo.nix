final: prev: {
  tempo = prev.tempo.overrideAttrs (old: rec {
    version = "2.10.1";

    src = prev.fetchFromGitHub {
      owner = "grafana";
      repo = "tempo";
      rev = "v${version}";
      hash = "sha256-KQiTH8+6wRmOdD86YG0r1LXuZ7l+zzIS41GwQGdtDwc=";
    };
  });
}
