import argparse
import debian.deb822
import json
import os
import shutil
import subprocess

parser = argparse.ArgumentParser(
    prog="debian-builder",
    description="Builds Debian packages from Nix store paths.",
)
parser.add_argument(
    "--output",
    help="Output directory path",
    default="",
)
args = parser.parse_args()

output_path: str = args.output
if output_path == "":
    output_path = "."

attrs_file = os.getenv("NIX_ATTRS_JSON_FILE")
assert attrs_file is not None

with open(attrs_file) as f:
    attrs = json.load(f)

contents = attrs["debianContent"]
assert isinstance(contents, list)

references = attrs["graph"]
assert isinstance(references, list)

for ref in references:
    assert isinstance(ref, dict)

    path = ref["path"]
    assert isinstance(path, str)

    ref_references = ref["references"]
    assert isinstance(ref_references, list)

    # Do not copy contents path unless there are self-references.
    if path in contents and path not in ref_references:
        continue

    _, _, path_tail = os.path.splitroot(path)
    assert not os.path.isabs(path_tail)
    dest = os.path.join(output_path, path_tail)
    if os.path.islink(path) or not os.path.isdir(path):
        print(f"copyfile {path} {dest}")
        shutil.copyfile(path, dest, follow_symlinks=False)
        continue
    print(f"copytree {path} {dest}")
    shutil.copytree(path, dest, symlinks=True, ignore_dangling_symlinks=True)

debian_control = attrs["debianControl"]
assert isinstance(debian_control, dict)
for k, v in debian_control.items():
    if v is None:
        del debian_control[k]
        continue
    assert isinstance(v, str)

debian_dir = os.path.join(output_path, "DEBIAN")
os.makedirs(debian_dir)
debian_control_path = os.path.join(debian_dir, "control")
print(f"dump {debian_control_path}")
with open(debian_control_path, "wb") as f:
    debian.deb822.Deb822(debian_control).dump(f)

for path in contents:
    print(f"copytree {path} {output_path}")
    shutil.copytree(
        path,
        output_path,
        symlinks=True,
        ignore_dangling_symlinks=True,
        dirs_exist_ok=True,
    )
