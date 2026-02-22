import os
import sys
import datetime
import argparse
import re
import hashlib
from pathlib import Path


def read_lines(path):
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        return f.readlines()


def parse_config(lines):
    entries = []
    clean_lines = [line for line in lines if not line.strip().startswith("#")]
    content = "".join(clean_lines)

    pattern = re.compile(r'([\w\-/"]+)\s*=\s*(.*?)\s*;', re.DOTALL)
    for raw_name, raw_body in pattern.findall(content):
        key_path = raw_name.strip().strip('"')
        raw_body = raw_body.strip()

        if raw_body.startswith("{"):
            excludes = []
            ex_match = re.search(r"exclude\s*=\s*\[(.*?)\]", raw_body, re.DOTALL)
            if ex_match:
                val_pattern = re.compile(r'"([^"]+)"')
                excludes = val_pattern.findall(ex_match.group(1))

            path_parts = key_path.rstrip("/").rsplit("/", 1)
            if len(path_parts) == 2:
                parent, target = path_parts
            else:
                parent, target = key_path, "."

            entries.append((parent, [target], excludes))

        elif raw_body.startswith("["):
            val_pattern = re.compile(r'"([^"]+)"')
            targets = val_pattern.findall(raw_body)
            entries.append((key_path, targets, []))

    return entries


def generate_env_content(target_dir, is_root_only=False, custom_excludes=None):
    target_path = Path(target_dir).resolve()
    base_name = target_path.name if target_path.name else "dotfiles"
    lines = [f"Structure of {base_name}\n"]

    ignore_patterns = {".git", "__pycache__", ".direnv", "result", "bin", "strategies"}
    if custom_excludes:
        ignore_patterns.update(custom_excludes)

    if is_root_only:
        lines.append(f"{os.path.basename(target_path)}/")
        files = [
            f
            for f in os.listdir(target_path)
            if os.path.isfile(os.path.join(target_path, f))
        ]
        for f in sorted(files):
            if f in ignore_patterns:
                continue
            if f.endswith((".pyc", ".png", ".jpg", ".pdf", ".txt", ".log")):
                continue
            if any(p in f for p in ["strategies"]):
                continue
            lines.append(f"    {f}")
        lines.append("\n--- File Contents ---")
        for f in sorted(files):
            if f in ignore_patterns:
                continue
            if f.endswith((".pyc", ".png", ".jpg", ".pdf", ".txt", ".log")):
                continue
            if any(p in f for p in ["strategies"]):
                continue
            file_path = os.path.join(target_path, f)
            lines.append(f"\n##### FILE: {f}\n")
            try:
                with open(file_path, "r", encoding="utf-8") as content_f:
                    lines.append(content_f.read())
            except Exception:
                lines.append("(Could not read file)")
    else:
        struct_data = []
        for root, dirs, files in os.walk(target_path):
            dirs[:] = [
                d for d in dirs if d not in ignore_patterns and "strategies" not in d
            ]
            level = Path(root).relative_to(target_path).parts
            indent = " " * 4 * len(level)
            struct_data.append(f"{indent}{os.path.basename(root)}/")
            sub_indent = " " * 4 * (len(level) + 1)
            for f in sorted(files):
                if f in ignore_patterns:
                    continue
                if f.endswith((".pyc", ".png", ".jpg", ".pdf", ".txt", ".log")):
                    continue
                if "strategies" in f:
                    continue
                struct_data.append(f"{sub_indent}{f}")
        lines.extend(struct_data)

        lines.append("\n--- File Contents ---")
        for root, dirs, files in os.walk(target_path):
            dirs[:] = [
                d for d in dirs if d not in ignore_patterns and "strategies" not in d
            ]
            if any(
                "strategies" in part
                for part in Path(root).relative_to(target_path).parts
            ):
                continue
            for f in sorted(files):
                if f in ignore_patterns:
                    continue
                if f.endswith((".pyc", ".png", ".jpg", ".pdf", ".txt", ".log")):
                    continue
                if "strategies" in f:
                    continue
                file_path = os.path.join(root, f)
                rel_path = os.path.relpath(file_path, target_path)
                lines.append(f"\n##### FILE: {rel_path}\n")
                try:
                    with open(file_path, "r", encoding="utf-8") as content_f:
                        lines.append(content_f.read())
                except Exception:
                    lines.append("(Could not read file)")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", help="Path to the config file")
    args = parser.parse_args()

    home = Path.home()
    base_dir = os.environ.get("LPT_APPS_DIR", str(home / "dotfiles/apps/lpt"))
    config_path = (
        args.config if args.config else os.path.join(base_dir, "env/env.txt_maker.nix")
    )

    output_base = home / "dotfiles/txt-maker"
    output_base.mkdir(parents=True, exist_ok=True)

    entries = parse_config(read_lines(config_path))

    for rel_root, dir_names, excludes in entries:
        src_root = home / rel_root
        clean_rel_root = re.sub(r"^dotfiles/?", "", rel_root)
        dst_root = output_base / clean_rel_root

        for name in dir_names:
            target_src = (src_root / name).resolve()
            if not target_src.is_dir():
                continue

            is_root_only = name == "."
            folder_name = "root" if is_root_only else name
            target_dst_dir = dst_root / folder_name
            target_dst_dir.mkdir(parents=True, exist_ok=True)

            new_content = generate_env_content(
                str(target_src), is_root_only=is_root_only, custom_excludes=excludes
            )
            new_hash = hashlib.md5(new_content.encode("utf-8")).hexdigest()

            existing_files = list(target_dst_dir.glob("*.txt"))
            should_write = True

            for old_f in existing_files:
                try:
                    old_content = old_f.read_text(encoding="utf-8")
                    if hashlib.md5(old_content.encode("utf-8")).hexdigest() == new_hash:
                        should_write = False
                        break
                except Exception:
                    continue

            if should_write:
                for old_f in existing_files:
                    try:
                        old_f.unlink()
                    except Exception:
                        pass
                now = datetime.datetime.now(datetime.timezone.utc)
                file_label = rel_root.replace("/", "_")
                if name != ".":
                    file_label += f"_{name}"
                else:
                    file_label += "_root"
                ts_name = (
                    f"{file_label}_{now.day:02d}_{now.hour:02d}{now.minute:02d}.txt"
                )
                out_path = target_dst_dir / ts_name
                out_path.write_text(new_content, encoding="utf-8")


if __name__ == "__main__":
    main()
