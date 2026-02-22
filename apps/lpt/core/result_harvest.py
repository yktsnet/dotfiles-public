import os
import subprocess
from datetime import datetime


def harvest():
    remote_host = "het"
    home_dir = os.path.expanduser("~")

    sync_dirs = [
        "ops_data/bars",
        "ops_data/state",
        "ops_data/logs",
        "ops_data/output",
        "dotfiles/apps/bt/results",
        "dotfiles/apps/bt/docs",
    ]

    for rel_path in sync_dirs:
        local_path = os.path.join(home_dir, rel_path)
        remote_path = f"{remote_host}:{rel_path}/"

        os.makedirs(local_path, exist_ok=True)

        cmd = [
            "rsync",
            "-avz",
            "--delete",
            "-e",
            "ssh -o BatchMode=yes -o ConnectTimeout=15",
            remote_path,
            local_path,
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            if result.returncode == 0:
                if (
                    "receiving file list" in result.stdout
                    and len(result.stdout.splitlines()) > 4
                ):
                    print(f"[{ts}] Mirrored changes from {rel_path} (with --delete)")
            else:
                print(f"[{ts}] Error mirroring {rel_path}: {result.stderr}")
        except Exception as e:
            print(f"Sync failed for {rel_path}: {str(e)}")


if __name__ == "__main__":
    harvest()
