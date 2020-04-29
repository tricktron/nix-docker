{ sources ? import ./nix/sources.nix }:
with
  { overlay = _: pkgs:
      { niv = import sources.niv {};
      };
  };
let pkgs = import sources.nixpkgs
  { overlays = [ overlay ] ; config = {}; };
  inherit (pkgs) closureInfo;
  inherit (pkgs.dockerTools) buildLayeredImage;
in
buildLayeredImage rec {
    name = "nix-docker";
    contents = with pkgs; [
        cacert
        bashInteractive
        coreutils
        nix
    ];
     extraCommands = ''
      # create the Nix DB
      export NIX_REMOTE=local?root=$PWD
      export USER=nobody
      ${contents}/bin/nix-store --load-db < ${closureInfo { rootPaths = [ contents ]; }}/registration

      # set the user profile
      ${contents}/bin/nix-env --profile nix/var/nix/profiles/default --set ${contents}

      # minimal
      mkdir -p bin usr/bin
      ln -s /nix/var/nix/profiles/default/bin/sh bin/sh
      ln -s /nix/var/nix/profiles/default/bin/env usr/bin/env

      # might as well...
      ln -s /nix/var/nix/profiles/default/bin/bash bin/bash
    '';

    config = {
      Cmd = [ "/nix/var/nix/profiles/default/bin/bash" ];
      Env = [
        "ENV=/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
        "GIT_SSL_CAINFO=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"
        "LD_LIBRARY_PATH=/nix/var/nix/profiles/default/lib"
        "PAGER=cat"
        "PATH=/nix/var/nix/profiles/default/bin"
        "SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"
      ];
    };
}
