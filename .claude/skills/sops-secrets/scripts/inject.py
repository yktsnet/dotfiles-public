"""
inject.py
Encrypts a given file using SOPS and age and moves it to the appropriate secrets directory.
If the operation is successful, the original file is deleted.
"""

import sys
import subprocess
import re
from pathlib import Path


def get_age_keys():
    """
    Parses the .sops.yaml file to extract all unique age public keys.
    """
    sops_yaml = Path.home() / "dotfiles/.sops.yaml"
    if not sops_yaml.exists():
        print(f"Error: {sops_yaml} not found.")
        sys.exit(1)
    content = sops_yaml.read_text()
    # Find all age public keys starting with 'age1'
    keys = sorted(list(set(re.findall(r"age1\w+", content))))
    return ",".join(keys)


def detect_format(filename: str) -> str:
    """
    Detects the SOPS file format based on the file extension.
    """
    stem = filename.removesuffix(".age")
    if stem.endswith(".env"):
        return "dotenv"
    if stem.endswith(".json"):
        return "json"
    return "binary"


def inject(src_path, category="ops"):
    """
    Copies the source file to a target secrets directory based on category,
    encrypts the copied file in-place using SOPS, and then removes the original file.
    """
    src = Path(src_path)
    if not src.exists():
        print(f"Error: {src} not found.")
        sys.exit(1)

    dest_dir = Path.home() / "dotfiles/secrets" / category
    dest_dir.mkdir(parents=True, exist_ok=True)

    fmt = detect_format(src.name)
    # Ensure the destination file name ends with .age
    dest_name = src.name if src.name.endswith(".age") else src.name + ".age"
    dest_file = dest_dir / dest_name

    # まずdestにコピーしてからsops --in-placeで暗号化
    # Copy the file to destination first before encrypting it in-place
    import shutil

    shutil.copy2(src, dest_file)

    dotfiles_dir = Path.home() / "dotfiles"

    # Command to run sops encryption targeting the specific file format
    cmd = [
        "sops",
        "--config",
        str(dotfiles_dir / ".sops.yaml"),
        "--encrypt",
        "--input-type",
        fmt,
        "--output-type",
        fmt,
        "--in-place",
        str(dest_file),
    ]
    try:
        # Run SOPS command from the dotfiles directory so configuration paths resolve correctly
        subprocess.run(cmd, check=True, cwd=str(dotfiles_dir))

        # Verify the file was properly written
        if dest_file.stat().st_size > 0:
            src.unlink() # Delete the original unencrypted file
            print(f"✓ Encrypted [{fmt}]: {dest_file}")
        else:
            print("Error: Resulting file is empty.")
            dest_file.unlink(missing_ok=True)
            sys.exit(1)
    except subprocess.CalledProcessError:
        print("Error: Encryption failed.")
        dest_file.unlink(missing_ok=True)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: inject <file_path> [category]")
        sys.exit(1)
    path = sys.argv[1]
    category = sys.argv[2] if len(sys.argv) > 2 else "ops"
    inject(path, category)
