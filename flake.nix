{
  description = "A flake for building Debian packages from Nix derivation outputs.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      nixpkgsForSystem = inputs.nixpkgs.legacyPackages;
      forPackages = pkgs: { buildDebianPackage = pkgs.callPackage ./build-debian-package.nix { }; };
    in
    {
      formatter = lib.genAttrs systems (system: nixpkgsForSystem.${system}.nixfmt-rfc-style);

      overlays.default = final: _: forPackages final;

      bundlers = lib.genAttrs systems (
        system:
        let
          inherit (forPackages nixpkgsForSystem.${system}) buildDebianPackage;
        in
        {
          default =
            drv:
            buildDebianPackage {
              name = "${drv.name}.deb";
              paths = [ drv ];
              debianControl = {
                Package = lib.getName drv;
                Version = lib.getVersion drv;
                Description = drv.meta.description or null;
                Maintainer =
                  let
                    maintainers = drv.meta.maintainers or [ ];
                  in
                  if maintainers != [ ] then
                    let
                      m = lib.head maintainers;
                    in
                    "${m.name} <${m.email or ""}>"
                  else
                    null;
              };
            };
        }
      );
    };
}
