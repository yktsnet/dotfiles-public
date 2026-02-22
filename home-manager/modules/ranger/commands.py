import os
import sys
import subprocess
import tempfile
import base64
import shutil
import socket
from ranger.api.commands import Command


_ranger_conf_dir = os.path.dirname(os.path.abspath(__file__))
if _ranger_conf_dir not in sys.path:
    sys.path.append(_ranger_conf_dir)
import ops_action


def copy_to_clipboard(text):
    if shutil.which("wl-copy") and os.environ.get("WAYLAND_DISPLAY"):
        try:
            subprocess.run(["wl-copy"], input=text.encode("utf-8"), check=True)
            return True
        except Exception:
            pass
    try:
        data = base64.b64encode(text.encode("utf-8")).decode("utf-8")
        osc52 = f"\033]52;c;{data}\a"
        if "TMUX" in os.environ:
            osc52 = f"\033Ptmux;\033{osc52}\033\\"
        with open("/dev/tty", "w") as tty:
            tty.write(osc52)
            tty.flush()
        return True
    except Exception:
        return False


class fzf_locate(Command):
    def execute(self):
        with tempfile.NamedTemporaryFile(delete=False) as tf:
            tf_path = tf.name
        cmd = f"fd --type f --hidden --exclude .git . ~/dotfiles | fzf --exact --height 70% --reverse --preview 'bat --color=always --style=numbers --line-range=:500 {{}}' > '{tf_path}'"
        self.fm.ui.suspend()
        try:
            subprocess.run(cmd, shell=True, executable="/bin/sh")
        finally:
            self.fm.ui.initialize()
        if os.path.exists(tf_path):
            with open(tf_path, "r") as f:
                result = f.read().strip()
            os.remove(tf_path)
            if result:
                target = os.path.abspath(result)
                if os.path.exists(target):
                    self.fm.select_file(target)
                    subprocess.run(
                        [
                            "python3",
                            os.path.expanduser("~/dotfiles/zsh/path_history.py")
                            "save",
                            target,
                        ]
                    )


class fzf_grep(Command):
    def execute(self):
        with tempfile.NamedTemporaryFile(delete=False) as tf:
            tf_path = tf.name
        cmd = f"rg --column --line-number --no-heading --color=always --smart-case . ~/dotfiles | fzf --exact --ansi --delimiter : --nth 4.. --height 70% --reverse --preview 'bat --color=always --style=numbers --highlight-line {{2}} --line-range={{2}}:+50 {{1}}' > '{tf_path}'"
        self.fm.ui.suspend()
        try:
            subprocess.run(cmd, shell=True, executable="/bin/sh")
        finally:
            self.fm.ui.initialize()
        if os.path.exists(tf_path):
            with open(tf_path, "r") as f:
                out = f.read().strip()
            os.remove(tf_path)
            parts = out.split(":")
            if len(parts) >= 1:
                target_file = os.path.abspath(parts[0])
                if os.path.exists(target_file):
                    self.fm.select_file(target_file)
                    subprocess.run(
                        [
                            "python3",
                            os.path.expanduser("~/dotfiles/apps/zsh/path_history.py"),
                            "save",
                            target_file,
                        ]
                    )


class fzf_history(Command):
    def execute(self):
        script_path = os.path.expanduser("~/dotfiles/apps/zsh/path_history.py")
        cmd = f"python3 {script_path}"
        self.fm.ui.suspend()
        try:
            target = subprocess.check_output(cmd, shell=True).decode().strip()
            if target and os.path.exists(target):
                self.fm.select_file(target)
        except subprocess.CalledProcessError:
            pass
        finally:
            self.fm.ui.initialize()


class fzf_git_diff(Command):
    def execute(self):
        dotfiles_path = os.path.expanduser("~/dotfiles")
        cmd = f"git -C {dotfiles_path} ls-files --others --modified --exclude-standard && git -C {dotfiles_path} diff --name-only @{{u}}...HEAD"
        fzf_cmd = f"({cmd}) | sort -u | fzf --exact --height 70% --reverse --preview 'bat --color=always --style=numbers {dotfiles_path}/{{}}'"
        self.fm.ui.suspend()
        try:
            target = (
                subprocess.check_output(fzf_cmd, shell=True, stderr=subprocess.STDOUT)
                .decode()
                .strip()
            )
            if target:
                abs_path = os.path.join(dotfiles_path, target)
                if os.path.exists(abs_path):
                    self.fm.select_file(abs_path)
        except subprocess.CalledProcessError:
            pass
        finally:
            self.fm.ui.initialize()


class smart_move(Command):
    def execute(self):
        if not self.arg(1):
            return
        target = os.path.expanduser(self.rest(1))
        selection = self.fm.thistab.get_selection()
        if not selection:
            return
        dotfiles_root = os.path.abspath(os.path.expanduser("~/dotfiles"))
        files = []
        for f in selection:
            abs_p = os.path.abspath(f.path)
            if abs_p == dotfiles_root or abs_p.startswith(dotfiles_root + os.sep):
                self.fm.notify(
                    f"Guard: Restricted move in dotfiles: {f.path}", bad=True
                )
                return
            files.append(f.path)
        try:
            cmd = ["mv", "-n"] + files + [target]
            subprocess.run(cmd, check=True)
            self.fm.reload_cwd()
            self.fm.notify(f"Successfully moved to {target}")
        except Exception as e:
            self.fm.notify(f"Move Error: {str(e)}", bad=True)


class action(Command):
    def execute(self):
        if not self.arg(1):
            return
        mode = self.arg(1)
        dotfiles_root = os.path.abspath(os.path.expanduser("~/dotfiles"))
        if mode == "m":
            self.fm.open_console("smart_move ")
        elif mode == "md":
            self.fm.execute_console("smart_move ~/Downloads")
        elif mode == "mh":
            self.fm.cd(os.environ["HOME"])
        elif mode == "i":
            if self.fm.thisfile.is_file and self.fm.thisfile.image:
                self.fm.execute_command(
                    f'kitty +kitten icat --transfer-mode=file --silent "{self.fm.thisfile.path}"; read -rsn 1'
                )
        elif mode == "e":
            if self.fm.thisfile.is_file:
                if self.fm.thisfile.image:
                    if socket.gethostname() == "<REMOTE_HOST>":
                        self.fm.notify("Remote image preview not supported")
                    else:
                        self.fm.execute_command(
                            f'kitty @ launch --location=vsplit --cwd=current --window-title "Image Preview" kitty +kitten icat --hold "{self.fm.thisfile.path}"'
                        )
                    return
                if socket.gethostname() == "<REMOTE_HOST>":
                    self.fm.execute_command(f'hx "{self.fm.thisfile.path}"')
                else:
                    self.fm.execute_command(
                        f"WIN_ID=$(kitty @ ls | jq -r '.[] | .tabs[] | .windows[] | select(.title == \"Helix Sidebar\") | .id'); "
                        f'[ -n "$WIN_ID" ] && kitty @ close-window --match id:$WIN_ID; '
                        f'kitty @ launch --location=vsplit --cwd=current --window-title "Helix Sidebar" hx "{self.fm.thisfile.path}"'
                    )
        elif mode == "ac":
            files = self.fm.thistab.get_selection()
            if not files:
                return
            output = []
            for f in files:
                if f.is_file:
                    rel_path = f.path.replace(os.environ["HOME"], "~")
                    header = f"--- {rel_path} ---\n"
                    try:
                        with open(f.path, "r", encoding="utf-8") as content:
                            output.append(header + content.read())
                    except Exception as e:
                        output.append(header + f"Error reading file: {str(e)}")
            if output:
                final_text = "\n\n".join(output)
                if copy_to_clipboard(final_text):
                    self.fm.notify(f"Copied {len(output)} files to clipboard")
        elif mode == "d":
            selection = self.fm.thistab.get_selection()
            files = []
            for f in selection:
                abs_p = os.path.abspath(f.path)
                if abs_p == dotfiles_root:
                    self.fm.notify("Guard: Cannot delete dotfiles root", bad=True)
                    return
                files.append(f.path)
            if files:
                subprocess.run(["trash-put"] + files)
                self.fm.reload_cwd()
                self.fm.notify("Trashed successfully!")
        elif mode == "u":
            if self.fm.thisfile.is_file:
                path = self.fm.thisfile.path
                base_dir = os.path.splitext(path)[0]
                cmd = ""
                if path.endswith(".zip"):
                    cmd = f'mkdir -p "{base_dir}" && unzip "{path}" -d "{base_dir}"'
                elif path.endswith((".tar.gz", ".tgz")):
                    cmd = f'mkdir -p "{base_dir}" && tar -xzf "{path}" -C "{base_dir}"'
                elif path.endswith((".tar.xz", ".txz")):
                    cmd = f'mkdir -p "{base_dir}" && tar -xJf "{path}" -C "{base_dir}"'
                if cmd:
                    self.fm.execute_command(f'{cmd} && trash-put "{path}"')
                    self.fm.reload_cwd()
                    self.fm.notify("Unarchived and original trashed")
                else:
                    self.fm.run("undo")
            else:
                self.fm.run("undo")
        elif mode == "p":
            if copy_to_clipboard(
                self.fm.thisfile.path.replace(os.environ["HOME"], "~")
            ):
                self.fm.notify("Copied relative path")
        elif mode == "P":
            if copy_to_clipboard(self.fm.thisfile.path):
                self.fm.notify("Copied absolute path")
        elif mode == "g":
            self.fm.execute_command("lazygit")
        elif mode == "r":
            self.fm.open_console("rename " + self.fm.thisfile.relative_path)
        else:
            target = self.rest(1)
            if target:
                full_path = os.path.join(self.fm.thisdir.path, target)
                if target.endswith("/") or target.startswith("/"):
                    os.makedirs(full_path.rstrip("/"), exist_ok=True)
                else:
                    if not os.path.exists(os.path.dirname(full_path)):
                        os.makedirs(os.path.dirname(full_path), exist_ok=True)
                    open(full_path, "a").close()
                self.fm.reload_cwd()


class exec_file(Command):
    def execute(self):
        ops_action.execute_target(self.fm, self.fm.thisfile.path)


class sync_het(Command):
    def execute(self):
        ops_action.sync_targets(self.fm, self.fm.thistab.get_selection())
