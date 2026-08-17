{
  description = "dimunyx-qs — a quickshell fork with a preconfigured bar";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    wall-archive.url = "github:vimlinuz/wall-archive";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, wall-archive, quickshell }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      runtimeDeps = [
        pkgs.brightnessctl
        pkgs.playerctl
        pkgs.cliphist
        pkgs.wl-clipboard
        pkgs.cava
        pkgs.lm_sensors
        pkgs.power-profiles-daemon
        pkgs.bluez
      ];

      qsPkg = quickshell.packages.${system}.default;

      quickshell-wrapped = pkgs.symlinkJoin {
        name = "quickshell-wrapped-${qsPkg.version}";
        paths = [ qsPkg ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/quickshell \
            --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
          wrapProgram $out/bin/qs \
            --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
        '';
      };

      dimunyx-qs = pkgs.stdenv.mkDerivation {
        pname = "dimunyx-qs";
        version = "0.1.1";
        src = self.outPath;

        dontBuild = true;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        installPhase = ''
          mkdir -p $out/share/dimunyx-qs
          cp -r . $out/share/dimunyx-qs/

          rm -rf $out/share/dimunyx-qs/.git
          rm -rf $out/share/dimunyx-qs/nix
          rm -f $out/share/dimunyx-qs/flake.nix
          rm -f $out/share/dimunyx-qs/flake.lock
          rm -f $out/share/dimunyx-qs/.envrc
          rm -f $out/share/dimunyx-qs/.gitignore
          rm -f $out/share/dimunyx-qs/README.md
          rm -f $out/share/dimunyx-qs/LICENSE
          rm -f $out/share/dimunyx-qs/deps-check.sh
          rm -f $out/share/dimunyx-qs/opencode.jsonc
          rm -f $out/share/dimunyx-qs/result

          mkdir -p $out/bin

          for name in dimunyx-qs quickshell qs; do
            cat > $out/bin/$name <<WRAPPER
#!${pkgs.bash}/bin/bash
for arg in "\$@"; do
  if [ "\$arg" = "--version" ] || [ "\$arg" = "-V" ]; then
    echo "dimunyx-qs 0.1.1 (revision tag-v0.1.1, distributed by dimunyx)"
    exit 0
  fi
done
exec ${quickshell-wrapped}/bin/quickshell "\$@"
WRAPPER
            chmod +x $out/bin/$name
          done
          # Wrap with PATH deps
          for name in dimunyx-qs quickshell qs; do
            wrapProgram $out/bin/$name \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
          done
        '';

        meta = {
          mainProgram = "dimunyx-qs";
        };
      };
    in
    {
      packages.${system} = {
        default = dimunyx-qs;
        inherit dimunyx-qs quickshell-wrapped;
      };

      apps.${system}.default = {
        type = "app";
        program = "${qsPkg}/bin/quickshell";
        meta = {
          mainProgram = "quickshell";
          description = "dimunyx-qs — quickshell fork bar";
        };
      };

      homeManagerModules.${system}.default =
        import ./nix/hm-module.nix { inherit dimunyx-qs wall-archive; };
    };
}
