#!/usr/bin/env bash
# PreToolUse hook (Bash): 元のチェックアウトでブランチを作る・切り替えるのを拒否する。
# 2つのセッションが同じチェックアウトでブランチを切ると、未コミットの変更が切り替えに運ばれて
# 相手のブランチへ移り、相手のコミットに混ざる。ブランチを切る作業は自分の worktree で行う。
# 通すもの: main へ戻る switch / checkout、ファイルを戻す checkout（-- 付き・実在するパス・
# 複数の位置引数）、worktree の中の切り替え、git worktree add、-C で worktree を指した切り替え。
# 判定はコマンド位置で行う。引用符の中身と heredoc の本文は文字列でありコマンドではない。
set -u

input=$(</dev/stdin)

# 元のチェックアウトかどうかは git-dir と git-common-dir が同じかで見る。worktree では
# git-dir が .git/worktrees/<名前> になり common-dir と分かれる。判定ディレクトリは入力の cwd
# （-C と cd があれば辿った先）で引く。CLAUDE_PROJECT_DIR は EnterWorktree で移っても
# 元のチェックアウトを指したままなので使わない。
reason=$(printf '%s' "$input" | python3 -c '
import json, os, re, shlex, subprocess, sys

d = json.load(sys.stdin)
cmd = d.get("tool_input", {}).get("command", "")
cwd = d.get("cwd") or ""

# heredoc の本文を外す
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

# 引用符の外にある区切り（; & | 改行 ( ) `）で割る。引用符の中の区切りでは割らない
segs, buf, q, i = [], [], None, 0
while i < len(text):
    c = text[i]
    if c == "\\" and q != "\x27" and i + 1 < len(text):
        buf.append(text[i:i + 2])
        i += 2
        continue
    if q:
        if c == q:
            q = None
        buf.append(c)
    elif c in "\x27\"":
        q = c
        buf.append(c)
    elif c in ";&|\n()`":
        segs.append("".join(buf))
        buf = []
    else:
        buf.append(c)
    i += 1
segs.append("".join(buf))

def git(where, *args):
    r = subprocess.run(["git", "-C", where, *args], capture_output=True, text=True)
    return r.returncode, r.stdout.strip()

def in_checkout(where):
    rc, gd = git(where, "rev-parse", "--path-format=absolute", "--git-dir")
    if rc != 0:
        return False
    _, cd = git(where, "rev-parse", "--path-format=absolute", "--git-common-dir")
    return gd == cd

def step(where, path):
    return os.path.join(where, os.path.expanduser(path))

def has(a, names, shorts):
    return a in names or any(a.startswith(s) for s in shorts) or any(a.startswith(n + "=") for n in names if n.startswith("--"))

def moves(sub, args, where):
    if sub == "switch":
        if any(has(a, ("-c", "-C", "--create", "--force-create", "-d", "--detach", "--orphan"), ("-c", "-C")) for a in args):
            return True
        pos = [a for a in args if not a.startswith("-")]
        return "-" in args or (bool(pos) and pos[0] != "main")
    if any(has(a, ("--orphan", "--detach", "--track", "-t"), ("-b", "-B")) for a in args if a != "--"):
        return True
    if "--" in args:
        return False
    pos = [a for a in args if not a.startswith("-")]
    if "-" in args:
        return True
    if not pos or pos[0] == "main" or len(pos) > 1:
        return False
    if os.path.exists(step(where, pos[0])):
        return False
    rc, _ = git(where, "rev-parse", "--verify", "-q", pos[0] + "^{commit}")
    if rc == 0:
        return True
    # 同名のローカルブランチが無く、リモート追跡ブランチだけあると checkout が作って切り替える
    _, refs = git(where, "for-each-ref", "--format=%(refname)", "refs/remotes")
    return any(r.split("/", 3)[-1] == pos[0] for r in refs.split())

skip = ("{", "!", "command", "env", "exec", "time", "sudo")
for seg in segs:
    toks = shlex.split(seg)
    while toks and (toks[0] in skip or re.match(r"^\w+=", toks[0])):
        toks.pop(0)
    if not toks:
        continue
    if toks[0] in ("cd", "pushd") and len(toks) > 1 and not toks[1].startswith("-"):
        cwd = step(cwd, toks[1])
        continue
    if os.path.basename(toks[0]) != "git":
        continue
    toks.pop(0)
    where = cwd
    while toks and toks[0].startswith("-"):
        o = toks.pop(0)
        if o == "-C" and toks:
            where = step(where, toks.pop(0))
        elif o in ("-c", "--git-dir", "--work-tree", "--namespace", "--exec-path") and toks:
            toks.pop(0)
    if len(toks) < 1 or toks[0] not in ("switch", "checkout"):
        continue
    if not where or not in_checkout(where):
        continue
    if moves(toks[0], toks[1:], where):
        print(" ".join(seg.split()))
        break
' 2>/dev/null)
status=$?

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

# 読めなかったときは通さない。判定できないまま素通りさせると防壁の意味が無くなる。
if [ $status -ne 0 ]; then
  case "$input" in
    *"git switch"*|*"git checkout"*|*"git -C"*) deny "フックが入力を解釈できなかった。判定できないため通さない。コマンドを単純な形（git switch / git checkout を1コマンドずつ）に分けて再実行する。" ;;
    *) exit 0 ;;
  esac
fi
[ -z "$reason" ] && exit 0

deny "元のチェックアウトではブランチを作らない・切り替えない（${reason}）。2つのセッションが同じチェックアウトで切り替えると、未コミットの変更が互いのブランチへ運ばれて混ざる。
- 新しい作業: git worktree add .claude/worktrees/<名前> -b <ブランチ> origin/main で worktree を作り、その中で作業する。作る前に git worktree list と開いている PR で同じ主題が無いか確かめる。
- 既存ブランチの続き: git worktree add .claude/worktrees/<名前> <既存ブランチ>
- main へ戻すだけなら git switch main は通る。ファイルを戻すなら git restore <パス>。"
