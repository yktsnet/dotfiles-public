import os
import subprocess
import re
import hashlib
from datetime import datetime

def get_hash(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()

def check_zsh():
    zsh_dir = os.path.expanduser("~/dotfiles/zsh")
    checker_dir = os.path.join(zsh_dir, "zsh-checker")
    
    if not os.path.exists(checker_dir):
        os.makedirs(checker_dir, exist_ok=True)

    test_nix = os.path.join(checker_dir, "test.nix")
    result_txt = os.path.join(checker_dir, "test_result.txt")
    temp_sh = "/tmp/lpt_zsh_test.sh"
    hash_file = "/tmp/lpt_zsh_test.hash"
    zsh_bin = "/run/current-system/sw/bin/zsh"

    if not os.path.exists(test_nix):
        return

    try:
        with open(test_nix, 'r', encoding='utf-8') as f:
            content = f.read()
        
        match = re.search(r"''([\s\S]*)''", content)
        if not match:
            return
            
        zsh_code = match.group(1).strip()
        current_hash = get_hash(zsh_code)

        if os.path.exists(hash_file):
            with open(hash_file, 'r') as f:
                if f.read().strip() == current_hash:
                    return

        with open(temp_sh, 'w', encoding='utf-8') as f:
            f.write(zsh_code)
            
        proc = subprocess.run(
            [zsh_bin, "-n", temp_sh],
            capture_output=True,
            text=True
        )
        
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(result_txt, 'w', encoding='utf-8') as f:
            f.write(f"[{ts}] Verification Result\n")
            if proc.returncode == 0:
                f.write("STATUS: OK\n")
            else:
                f.write("STATUS: NG\n")
                f.write("---\n")
                f.write(proc.stderr.replace(temp_sh, "test.nix"))
        
        with open(hash_file, 'w') as f:
            f.write(current_hash)
                
    except Exception as e:
        if os.path.exists(checker_dir):
            with open(result_txt, 'w', encoding='utf-8') as f:
                f.write(f"System Error: {str(e)}\n")

if __name__ == "__main__":
    check_zsh()