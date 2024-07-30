{
  lib,
  stdenv,
  runCommand,
  dpkg,
  python3,
}:
let
  python = python3.pythonOnBuildForHost.withPackages (ps: [ ps.debian ]);
in
{
  name ? "package.deb",
  # A list of paths for Debian package.
  paths ? [ ],
  extraCommands ? "",
  # Contents of the DEBIAN/control file.
  # Mandatory fields: Package, Version, Architecture, Maintainer, Description.
  # See https://debian.org/doc/debian-policy/ch-controlfields.html#debian-binary-package-control-files-debian-control
  #
  # Architecture defaults to stdenv.hostPlatform.linuxArch.
  debianControl ? { },
}:
let
  pathsList = lib.toList paths;
in
stdenv.mkDerivation {
  inherit name;

  __structuredAttrs = true;

  exportReferencesGraph.graph = pathsList;
  unsafeDiscardReferences.out = true;

  debianContent = pathsList;
  debianControl = {
    Architecture = stdenv.hostPlatform.linuxArch;
  } // debianControl;

  nativeBuildInputs = [
    python
    dpkg
  ];

  debianBuilder = ./debian-builder.py;

  dontUnpack = true;
  dontConfigure = true;
  dontFixup = true;
  doInstallCheck = true;

  buildPhase =
    ''
      runHook preBuild
      ${python.executable} -- "$debianBuilder" --output pkgroot
    ''
    + lib.optionalString (extraCommands != "") ''
      pushd pkgroot
      ${extraCommands}
      popd
    ''
    + ''
      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall
    dpkg-deb --build pkgroot "$out"
    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    dpkg --simulate --install "$out"
    runHook postInstallCheck
  '';
}
