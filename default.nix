{ sources ? import ./nix/sources.nix }:
with
  { overlay = _: pkgs:
      { niv = import sources.niv {};
      };
  };
let pkgs = import sources.nixpkgs
  { overlays = [ overlay ] ; config = {}; };
  inherit (pkgs.dockerTools) buildLayeredImage;
in
buildLayeredImage {
    name = "nix-docker";
    contents = [ pkgs.git ];
}