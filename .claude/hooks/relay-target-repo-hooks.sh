#!/usr/bin/env bash
# PreToolUse hook (Bash): 起動したリポとは別のリポを指すコマンドに、そのリポの PreToolUse フックと deny を当てる。
#
# Claude Code が読むのは起動したリポの .claude/settings.json だけで、cd や git -C で別のリポへ書き込むと、
# そのリポのフック（push・マージ・秘密情報の見張りなど）も deny も走らない。リポ横断の作業は普通に起きるので、
# 宛先のリポが持つ仕組みをここから呼ぶ。ルールを1本ずつグローバルへ写すと、リポが足したルールが横断では効かない。
#
# 宛先の割り出し: `cd <dir>` / `git -C <dir>` / `-R|--repo <owner>/<repo>` / `repos/<owner>/<repo>` /
# `github.com/<owner>/<repo>`。owner/repo は、~/github-*/<repo> のうち origin がその owner/repo を指す clone に寄せる。
# 宛先が起動したリポと同じ（worktree を含む）か、.claude/settings.json を持たなければ何もしない。
# 割り出せないコマンド（変数で組んだパスなど）は素通りする。網羅ではなく、横断でふだん打つ形を拾う層である。
set -u

input=$(</dev/stdin)

printf '%s' "$input" | python3 -c '
import fnmatch, glob, json, os, re, shlex, subprocess, sys

d = json.load(sys.stdin)
if d.get("tool_name") != "Bash":
    sys.exit(0)
cmd = d.get("tool_input", {}).get("command", "")
cwd = d.get("cwd") or os.getcwd()
home = os.path.expanduser("~")

# heredoc の本文はデータなので外す（PR 本文に git push と書いただけで当てない）
lines, delim, strip = [], None, False
for line in cmd.split("\n"):
    if delim is not None:
        if (line.lstrip("\t") if strip else line) == delim:
            delim = None
        continue
    lines.append(line)
    for m in re.finditer(r"(?<!<)<<(-?)[ \t]*[\"\x27]?([A-Za-z_][A-Za-z0-9_]*)[\"\x27]?", line):
        strip, delim = m.group(1) == "-", m.group(2)
text = "\n".join(lines)

def git(dirpath, *args):
    r = subprocess.run(["git", "-C", dirpath, *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""

def repo_of(path):
    path = os.path.expanduser(path.replace("$HOME", home))
    if not os.path.isabs(path):
        path = os.path.join(cwd, path)
    if not os.path.isdir(path):
        return None
    top = git(path, "rev-parse", "--show-toplevel")
    common = git(path, "rev-parse", "--path-format=absolute", "--git-common-dir")
    return (top, common, path) if top and common else None

def clone_of(owner, name):
    for p in sorted(glob.glob(os.path.join(home, "github-*", name))):
        if os.path.isdir(p) and re.search(r"[:/]" + re.escape(owner) + "/" + re.escape(name) + r"(\.git)?$",
                                          git(p, "remote", "get-url", "origin"), re.I):
            return repo_of(p)
    return None

targets = []
for m in re.finditer(r"(?:^|[;&|(\n]\s*)cd\s+([^\s;&|)]+)|git\s+-C\s+([^\s;&|]+)", text):
    t = repo_of(m.group(1) or m.group(2))
    if t:
        targets.append(t)
for m in re.finditer(r"(?:-R|--repo)[\s=]+([\w.-]+)/([\w.-]+)|repos/([\w.-]+)/([\w.-]+)|github\.com[/:]([\w.-]+)/([\w.-]+?)(?:\.git)?(?=[/\s\"\x27]|$)", text):
    g = [x for x in m.groups() if x]
    t = clone_of(g[0], g[1])
    if t:
        targets.append(t)

here = repo_of(os.environ.get("CLAUDE_PROJECT_DIR") or cwd)
here_common = here[1] if here else None

def segments(s):
    # 引用符の外の区切りで割り、deny の前方一致を区切りごとに当てる
    out, buf, q = [], [], None
    for c in s:
        if q:
            buf.append(c)
            if c == q:
                q = None
        elif c in "\"\x27":
            q = c
            buf.append(c)
        elif c in ";&|\n":
            out.append("".join(buf).strip())
            buf = []
        else:
            buf.append(c)
    out.append("".join(buf).strip())
    return [x for x in out if x]

seen = set()
for top, common, path in targets:
    if common == here_common or common in seen:
        continue
    seen.add(common)
    try:
        conf = json.load(open(os.path.join(top, ".claude", "settings.json")))
    except (OSError, ValueError):
        continue
    name = os.path.basename(top)

    for rule in conf.get("permissions", {}).get("deny", []):
        m = re.fullmatch(r"Bash\((.*)\)", rule)
        if not m:
            continue
        pat = m.group(1)
        for seg in segments(text):
            if fnmatch.fnmatchcase(seg, pat) or (pat.endswith(":*") and seg.startswith(pat[:-2])):
                print(f"D\t[{name}] このリポの settings.json が deny している（{rule}）。")
                sys.exit(0)

    payload = dict(d, cwd=path)
    env = dict(os.environ, CLAUDE_PROJECT_DIR=top)
    for entry in conf.get("hooks", {}).get("PreToolUse", []):
        matcher = entry.get("matcher") or "*"
        if matcher != "*" and not re.fullmatch(matcher, "Bash"):
            continue
        for h in entry.get("hooks", []):
            if h.get("type") != "command":
                continue
            c = h["command"].replace("$CLAUDE_PROJECT_DIR", shlex.quote(top)).replace("${CLAUDE_PROJECT_DIR}", shlex.quote(top))
            try:
                r = subprocess.run(c, shell=True, input=json.dumps(payload), capture_output=True, text=True,
                                   cwd=path, env=env, timeout=h.get("timeout", 10))
            except subprocess.TimeoutExpired:
                continue
            reason = None
            if r.returncode == 2:
                reason = r.stderr.strip() or "（理由なし）"
            elif r.returncode == 0 and r.stdout.strip().startswith("{"):
                try:
                    o = json.loads(r.stdout).get("hookSpecificOutput", {})
                except ValueError:
                    o = {}
                if o.get("permissionDecision") == "deny":
                    reason = o.get("permissionDecisionReason", "（理由なし）")
            if reason:
                hook = os.path.basename(h["command"].split()[0])
                reason = " ".join(reason.split())
                print(f"D\t[{name}] このリポのフック {hook} が止めた: {reason}")
                sys.exit(0)
' | {
  IFS= read -r verdict || exit 0
  case "$verdict" in
    D*)
      reason="${verdict#*$'\t'}"
      python3 -c 'import json,sys; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":sys.argv[1]+" 宛先のリポのルールは、起動したリポのセッションからも同じに当たる。そのリポの CLAUDE.md を読んで手順を確かめ、必要ならそのリポでセッションを開く。"}}, ensure_ascii=False))' "$reason"
      ;;
  esac
}
exit 0
