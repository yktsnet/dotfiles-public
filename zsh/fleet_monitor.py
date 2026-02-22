--- ~/dotfiles/apps/zsh/fleet_monitor.py ---
import subprocess
import socket
import sys
import os

def get_status(host, user, is_local):
    
    script_path = os.path.expanduser("~/dotfiles/apps/zsh/system_monitor.py")
    if is_local:
        cmd = ["python3", script_path]
        shell = False
    else:
    
        cmd = f"timeout 5 ssh {user}@{host} 'python3 -u -' < {script_path}"
        shell = True
    
    try:
        res = subprocess.check_output(cmd, shell=shell, text=True, stderr=subprocess.DEVNULL)
        return res.strip()
    except:
        return ""

def main():
    
    hosts = [("t14", "yktsnet"), ("het", "yktsnet")]
    inv = socket.gethostname()
    
    
    utc_time = subprocess.getoutput("date -u +'%F %T UTC'")
    print(f"time {utc_time}")
    
    
    print(f"{'Host':<4} {'State':<5} {'Load/C':>7} {'Mem%':>5} {'Disk%':>5} {'IOw%':>7} {'Offset':>9}")
    print("-" * 55)

    for h, user in hosts:
        out = get_status(h, user, h == inv)
        
        if not out:
            print(f"{h:<4} \033[31mDOWN\033[0m  {'---':>7} {'---':>5} {'---':>5} {'---':>7} {'---':>9}")
            continue
        
        try:
            state, lc, mem, dsk, iow, off = out.split('|')
            color = "\033[32m" if state == "OK" else "\033[33m" if state == "WARN" else "\033[31m"
            zc = "\033[0m"
            print(f"{h:<4} {color}{state:<5}{zc} {lc:>7} {mem:>4}% {dsk:>4}% {iow:>6}% {off:>9}")
        except:
            print(f"{h:<4} \033[31mERR\033[0m   {'---':>7} {'---':>5} {'---':>5} {'---':>7} {'---':>9}")

if __name__ == "__main__":
    main()
