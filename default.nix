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
     extraCommands = with pkgs; ''
      # create the Nix DB
      export NIX_REMOTE=local?root=$PWD
      export USER=nobody
      ${contents}/bin/nix-store --load-db < ${closureInfo { rootPaths = contents; }}/registration

      mkdir -p bin usr/bin etc/nix /nix/var/nix/profiles/per-user/root /root/.nix-defexpr
      ln -s ${bashInteractive}/bin/bash /bin/bash
      ln -s /bin/bash bin/sh
      ln -s ${coreutils}/bin/env usr/bin/env
      ln -s /nix/var/nix/profiles/per-user/root/profile /root/.nix-profile
      echo 'sandbox = false' > etc/nix/nix.conf
    '';

    config = {
      Cmd = [ "/bin/bash" ];
      Env = [
        "NIX_PAGER=cat"
        "PATH=/root/.nix-profile/bin:/bin:/usr/bin"
        "MANPATH=/root/.nix-profile/share/man"
        "NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_PATH=nixpkgs=${pkgs}"
      ];
    };
}
