"""
fleet_monitor.py
Monitors a fleet of remote machines by executing system_monitor.py locally or over SSH.
Provides a consolidated view of each machine's load, memory, disk usage, IO wait, and time offset.
"""

import subprocess
import socket
import sys
import os


def get_status(host, user, is_local):
    """
    Retrieves system status metrics by running system_monitor.py.
    """
    # system_monitor.py の絶対パス
    script_path = os.path.expanduser("~/dotfiles/apps/zsh/system_monitor.py")
    if is_local:
        cmd = ["python3", script_path]
        shell = False
    else:
        # リモート実行時もファイルを標準入力から送り込む形式を維持
        # Run over SSH by piping the local script to remote python
        cmd = f"timeout 5 ssh {user}@{host} 'python3 -u -' < {script_path}"
        shell = True

    try:
        # Execute command and capture output, suppressing stderr
        res = subprocess.check_output(
            cmd, shell=shell, text=True, stderr=subprocess.DEVNULL
        )
        return res.strip()
    except:
        return ""


def parse_fleet():
    """
    Reads the fleet definition from the FLEET env var.
    Format: "host:user,host:user" (e.g. "linux-laptop:ops,linux-server-a:ops").
    Host entries without a user fall back to the current login name.
    """
    raw = os.environ.get("FLEET", "").strip()
    if not raw:
        return []
    fleet = []
    for entry in raw.split(","):
        entry = entry.strip()
        if not entry:
            continue
        host, _, user = entry.partition(":")
        fleet.append((host, user or os.environ.get("USER", "")))
    return fleet


def main():
    # 実ホスト名・SSH ユーザは公開リポに直書きせず、環境変数から読む
    hosts = parse_fleet()
    if not hosts:
        print("FLEET is empty. Set e.g. FLEET=linux-laptop:ops,linux-server-a:ops", file=sys.stderr)
        return 1
    inv = socket.gethostname()

    # 時刻表示 / Show current UTC time
    utc_time = subprocess.getoutput("date -u +'%F %T UTC'")
    print(f"time {utc_time}")

    # ヘッダー / Print header
    print(
        f"{'Host':<18} {'State':<5} {'Load/C':>7} {'Mem%':>5} {'Disk%':>5} {'IOw%':>7} {'Offset':>9}"
    )
    print("-" * 69)

    for h, user in hosts:
        out = get_status(h, user, h == inv)

        if not out:
            # Output format for hosts that didn't respond
            print(
                f"{h:<18} \033[31mDOWN\033[0m  {'---':>7} {'---':>5} {'---':>5} {'---':>7} {'---':>9}"
            )
            continue

        try:
            # Parse output format provided by system_monitor.py
            state, lc, mem, dsk, iow, off = out.split("|")

            # Decide color based on state
            color = (
                "\033[32m"
                if state == "OK"
                else "\033[33m" if state == "WARN" else "\033[31m"
            )
            zc = "\033[0m"
            print(
                f"{h:<18} {color}{state:<5}{zc} {lc:>7} {mem:>4}% {dsk:>4}% {iow:>6}% {off:>9}"
            )
        except:
            # Output format for unparseable responses
            print(
                f"{h:<18} \033[31mERR\033[0m   {'---':>7} {'---':>5} {'---':>5} {'---':>7} {'---':>9}"
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
