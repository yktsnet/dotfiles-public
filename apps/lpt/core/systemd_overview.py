import sys
import os
import subprocess
from pathlib import Path
from collections import defaultdict

def load_env(path):
    data = {}
    if not path.exists():
        return data
    text = path.read_text(encoding="utf-8")
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        name, value = name.strip(), value.strip()
        if not name:
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
            value = value[1:-1]
        data[name] = value
    return data

def split_words(value):
    return [x for x in value.replace(",", " ").split() if x] if value else []

def ssh_stdout(host, remote_cmd):
    cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", host, remote_cmd]
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, text=True, check=False)
        return proc.stdout or ""
    except Exception:
        return ""

def collect_remote_timers_by_root(hosts, roots):
    result = {}
    for root in roots:
        root_map = result.setdefault(root, defaultdict(set))
        for host in hosts:
            remote_dir = f"~/dotfiles/apps/{root}/config/systemd/user"
            out = ssh_stdout(host, f"ls -1 {remote_dir}/*.timer 2>/dev/null || true")
            for line in out.splitlines():
                name = os.path.basename(line.strip())
                if name:
                    root_map[name].add(host)
    return result

def collect_local_timers_by_root(label, roots):
    result = {}
    home = Path.home()
    for root in roots:
        timer_dir = home / "dotfiles/apps" / root / "config" / "systemd" / "user"
        if not timer_dir.is_dir():
            continue
        root_map = result.setdefault(root, defaultdict(set))
        for path in sorted(timer_dir.glob("*.timer")):
            root_map[path.name].add(label)
    return result

def merge_root_timers(remote, local):
    merged = {}
    for src in (remote, local):
        for root, timers in src.items():
            dst = merged.setdefault(root, defaultdict(set))
            for name, devs in timers.items():
                dst[name].update(devs)
    return merged

def build_global_timers(root_timers):
    global_timers = defaultdict(set)
    for timers in root_timers.values():
        for name, devs in timers.items():
            global_timers[name].update(devs)
    return global_timers

def parse_loaded_timers_output(text):
    names = set()
    for line in text.splitlines():
        parts = line.strip().split()
        if len(parts) >= 2:
            unit = parts[-2]
            if unit.endswith(".timer"):
                names.add(unit)
    return names

def collect_remote_loaded_timers(hosts):
    return {host: parse_loaded_timers_output(ssh_stdout(host, "systemctl --user --no-pager list-timers --all --no-legend 2>/dev/null || true")) for host in hosts}

def collect_local_loaded_timers(label):
    try:
        proc = subprocess.run(["systemctl", "--user", "--no-pager", "list-timers", "--all", "--no-legend"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, check=False)
        return {label: parse_loaded_timers_output(proc.stdout)}
    except Exception:
        return {}

def merge_loaded_timers(remote_loaded, local_loaded):
    merged = {}
    for src in (remote_loaded, local_loaded):
        for dev, names in src.items():
            if names:
                merged.setdefault(dev, set()).update(names)
    return merged

def print_report(env, root_timers, global_timers, loaded_by_device):
    remote_hosts = split_words(env.get("LPT_SYSTEMD_REMOTE_HOSTS", ""))
    remote_roots = split_words(env.get("LPT_SYSTEMD_REMOTE_ROOTS", ""))
    local_roots = split_words(env.get("LPT_SYSTEMD_LOCAL_ROOTS", ""))
    local_label = env.get("LPT_SYSTEMD_LOCAL_NAME", "local") or "local"
    print("systemd timer overview\n")
    print(f"remote hosts: {' '.join(remote_hosts) if remote_hosts else '(none)'}")
    print(f"remote roots: {' '.join(remote_roots) if remote_roots else '(none)'}")
    print(f"local device: {local_label}")
    print(f"local roots: {' '.join(local_roots) if local_roots else '(none)'}\n")
    devices = sorted({d for devs in global_timers.values() for d in devs})
    if devices:
        print("devices:")
        for d in devices: print(" ", d)
        print()
    print(f"timer summary:\n  total timers: {len(global_timers)}\n")
    print("legend: host* = defined in config/systemd/user but not loaded by systemd\n")
    max_name = max((len(n) for n in global_timers.keys()), default=0)
    seen = set()
    roots = [r for r in remote_roots + local_roots if r and not (r in seen or seen.add(r))]
    for r in sorted(root_timers.keys()):
        if r and r not in seen: roots.append(r)
    print("all timers by root:")
    if not roots:
        print("  (none)")
        return
    for root in roots:
        print(f"  {root}/")
        timers = root_timers.get(root, {})
        if not timers:
            print("    (none)")
            continue
        for name in sorted(timers.keys()):
            labels = [dev if name in loaded_by_device.get(dev, set()) else dev + "*" for dev in sorted(timers[name])]
            print(f"    {name.ljust(max_name)}  {', '.join(labels)}")
        print()

def main():
    base = Path(__file__).resolve().parent.parent
    env = load_env(base / "env" / ".env.systemd")
    remote_hosts = split_words(env.get("LPT_SYSTEMD_REMOTE_HOSTS", ""))
    remote_roots = split_words(env.get("LPT_SYSTEMD_REMOTE_ROOTS", ""))
    local_roots = split_words(env.get("LPT_SYSTEMD_LOCAL_ROOTS", ""))
    if not remote_hosts and not local_roots:
        sys.exit(1)
    remote_root_timers = collect_remote_timers_by_root(remote_hosts, remote_roots)
    local_label = env.get("LPT_SYSTEMD_LOCAL_NAME", "local") or "local"
    local_root_timers = collect_local_timers_by_root(local_label, local_roots)
    root_timers = merge_root_timers(remote_root_timers, local_root_timers)
    global_timers = build_global_timers(root_timers)
    loaded_by_device = merge_loaded_timers(collect_remote_loaded_timers(remote_hosts), collect_local_loaded_timers(local_label))
    print_report(env, root_timers, global_timers, loaded_by_device)

if __name__ == "__main__":
    main()