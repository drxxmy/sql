{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          (staruml.overrideAttrs {
            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              mv opt $out
              mv usr/share $out
              rm -rf $out/share/doc

              substituteInPlace $out/share/applications/staruml.desktop \
                --replace-fail "/opt/StarUML/staruml" "$out/bin/staruml"

              mkdir -p $out/lib
              ln -s ${lib.getLib stdenv.cc.cc}/lib/libstdc++.so.6 $out/lib/
              ln -s ${lib.getLib systemd}/lib/libudev.so.1 $out/lib/libudev.so.0

              # Activate StarUML
              mkdir -p $out/opt/StarUML/resources
              cp -f ${./app.asar} $out/opt/StarUML/resources/app.asar

              patchelf --interpreter ${bintools.dynamicLinker} \
                --add-needed libGL.so.1 \
                $out/opt/StarUML/staruml

              ln -s $out/opt/StarUML/staruml $out/bin/staruml

              runHook postInstall
            '';
          })
        ];
        shellHook = ''
          tmuxinator .
        '';
      };
    };
}
