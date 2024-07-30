# Build Debian Package

Nix flake that provides a simple alternative to the [NixOS/bundlers] (and
[juliosueiras-nix/nix-utils] that it uses under the hood) for building Debian
packages.

Example:
```console
$ nix bundle --bundler github:tie-infra/debian-package nixpkgs#pkgsStatic.hello
```

Note that currently it builds only a single debian package for a set of store
paths.

[NixOS/bundlers]: https://github.com/NixOS/bundlers
[juliosueiras-nix/nix-utils]: https://github.com/juliosueiras-nix/nix-utils
