"""
system_monitor.py
Monitors key system metrics including load, memory, disk usage, io wait, and time offset.
Outputs a single pipe-separated line representing the host's overall state.
"""

import os
import socket
import subprocess
import sys
import time
from datetime import datetime

def get_load_ncpu():
    """
    Reads the 1-minute load average from /proc/loadavg and returns it along with the CPU count.
    """
    try:
        with open("/proc/loadavg", "r") as f:
            load1 = float(f.read().split()[0])
        ncpu = os.cpu_count() or 1
        return load1, ncpu
    except:
        return 0.0, 1

def get_mem_usage():
    """
    Parses /proc/meminfo to calculate memory usage percentage.
    """
    try:
        mem = {}
        with open("/proc/meminfo", "r") as f:
            for line in f:
                parts = line.split()
                if not parts: continue
                mem[parts[0]] = int(parts[1])
        total = mem.get("MemTotal:", 0)
        avail = mem.get("MemAvailable:", 0)
        if total > 0:
            return int(((total - avail) / total) * 100)
    except:
        pass
    return 0

def get_disk_usage():
    """
    Calculates the root disk usage percentage using os.statvfs.
    """
    try:
        st = os.statvfs("/")
        used = (st.f_blocks - st.f_bfree)
        total = st.f_blocks
        if total > 0:
            return int((used / total) * 100)
    except:
        pass
    return 0

def get_iowait():
    """
    Samples /proc/stat twice to calculate the current I/O wait percentage.
    """
    try:
        def read_stats():
            with open("/proc/stat", "r") as f:
                line = f.readline()
                parts = [int(x) for x in line.split()[1:]]
                return sum(parts), parts[4] # Total, iowait
        
        t1, i1 = read_stats()
        # Wait slightly to compute the delta
        time.sleep(0.2)
        t2, i2 = read_stats()
        dt = t2 - t1
        di = i2 - i1
        if dt > 0:
            return round((di * 100.0) / dt, 1)
    except:
        pass
    return 0.0

def get_offset():
    """
    Gets the current NTP time offset using chronyc or timedatectl.
    Returns the offset in milliseconds as a formatted string.
    """
    try:
        # Try chronyc first (preferred if chrony is installed)
        res = subprocess.run(["chronyc", "tracking"], capture_output=True, text=True, timeout=1)
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if "Last offset" in line:
                    val = line.split(":")[1].split()[0]
                    # Convert to milliseconds
                    return f"{float(val)*1000:.3f}"
        # Fallback to timedatectl output parsing
        res = subprocess.run(["timedatectl", "timesync-status"], capture_output=True, text=True, timeout=1)
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if "Offset" in line:
                    val = line.split(":")[1].strip()
                    # Basic conversion logic parsing digits and units separately
                    num = "".join(c for c in val if c.isdigit() or c in ".-")
                    unit = "".join(c for c in val if c.isalpha())
                    n = float(num)
                    if unit == "ms": return f"{n:.3f}"
                    if unit == "s": return f"{n*1000:.3f}"
                    if unit == "us": return f"{n/1000:.3f}"
    except:
        pass
    return "NA"

def hpi():
    """
    Gathers all system metrics and computes an overall state (OK, WARN, ALERT).
    Prints a pipe-delimited string of the results.
    """
    host = socket.gethostname()
    l1, cpu = get_load_ncpu()
    # Normalize load average by number of CPUs
    lc = f"{l1/cpu:.2f}"
    mem = get_mem_usage()
    disk = get_disk_usage()
    iow = get_iowait()
    off = get_offset()
    
    # State logic / Threshold checks
    state = "OK"
    if float(lc) > 1.5: state = "WARN"
    if mem >= 95 or disk >= 95: state = "ALERT"
    elif mem >= 90 or disk >= 90: state = "WARN"

    print(f"{state}|{lc}|{mem}|{disk}|{iow}|{off}")

if __name__ == "__main__":
    hpi()