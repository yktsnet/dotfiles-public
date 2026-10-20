#!/usr/bin/env python3
"""決定的に確かめられる参照の食い違いを検出する。リポのルートで実行する。

- Markdown の相対リンク先の不在
- settings.json のフック登録と .claude/hooks/*.sh の実体の食い違い
- .claude/skills/ の skill が README.md の一覧から張られていない
問題は1件1行で出力し、1件でもあれば終了コード1。
"""
import re
import subprocess
import sys
from pathlib import Path

LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
FENCE = re.compile(r"^\s*(```|~~~)")
CODE_SPAN = re.compile(r"`[^`]*`")
SCHEME = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
SKIP_PREFIX = ("issues/done/",)


def tracked_markdown():
    out = subprocess.run(
        ["git", "ls-files", "*.md"], capture_output=True, text=True, check=True
    ).stdout
    return [Path(p) for p in out.splitlines() if p]


def check_links(root):
    problems = []
    for md in tracked_markdown():
        if str(md).startswith(SKIP_PREFIX) or not md.is_file():
            continue
        in_fence = False
        for lineno, line in enumerate(md.read_text(encoding="utf-8").splitlines(), 1):
            if FENCE.match(line):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for target in LINK.findall(CODE_SPAN.sub("", line)):
                if target.startswith(("#", "<")) or SCHEME.match(target):
                    continue
                path = target.split("#", 1)[0]
                if not path:
                    continue
                base = root if path.startswith("/") else md.parent
                if not (base / path.lstrip("/")).exists():
                    problems.append(f"broken link: {md}:{lineno} -> {target}")
    return problems


def check_hooks():
    settings = Path(".claude/settings.json")
    hooks_dir = Path(".claude/hooks")
    registered = set(re.findall(r"hooks/([\w.-]+\.sh)", settings.read_text(encoding="utf-8")))
    present = {p.name for p in hooks_dir.glob("*.sh")}
    problems = []
    for name in sorted(registered - present):
        problems.append(f"hook registered in settings.json but missing in .claude/hooks/: {name}")
    for name in sorted(present - registered):
        problems.append(f"hook present in .claude/hooks/ but not registered in settings.json: {name}")
    return problems


def check_skill_index():
    skills = Path(".claude/skills")
    readme = (skills / "README.md").read_text(encoding="utf-8")
    problems = []
    for d in sorted(p for p in skills.iterdir() if p.is_dir()):
        if f"({d.name}/" not in readme:
            problems.append(f"skill not linked from .claude/skills/README.md: {d.name}")
    return problems


def main():
    root = Path.cwd()
    problems = check_links(root) + check_hooks() + check_skill_index()
    for p in problems:
        print(p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
