"""
apps/lpt/link_guarantees.py

フリート横断で保証台帳（docs/guarantees.md）を1箇所に集約する。
各リポの docs/guarantees.md は正本のまま書き換えず、集約先ディレクトリに相対 symlink を張るだけに留める。
home-manager の activation script（home-manager/modules/guarantees.nix）から rebuild のたびに呼ばれる想定。

パスは全て環境変数から受け取り、コード内には個人のディレクトリ名を持たない。
- GUARANTEES_TARGET_DIR: symlink を集める先。既定 ~/guarantees
- GUARANTEES_SEARCH_DIRS: ":" 区切りの走査対象。列挙の順序がそのまま優先順位になる
  （同名リポが複数の走査対象で見つかったとき、先に書いた方が接頭辞なしの名前を取る）。既定は $HOME のみ
- GUARANTEES_CACHE_FILE: 前回の集約状態を記録するキャッシュ。既定 ~/.cache/lpt_guarantees_state.json
"""

import os
import json
import pathlib


def get_target_dir() -> pathlib.Path:
    default = pathlib.Path.home() / "guarantees"
    return pathlib.Path(os.environ.get("GUARANTEES_TARGET_DIR", str(default))).expanduser()


def get_search_dirs() -> list[pathlib.Path]:
    raw = os.environ.get("GUARANTEES_SEARCH_DIRS", "")
    if raw.strip():
        # ":" 区切り。この順序がそのまま優先順位になる（衝突解決の唯一の根拠）
        parts = raw.split(":")
    else:
        parts = [str(pathlib.Path.home())]
    return [pathlib.Path(p).expanduser() for p in parts if p.strip()]


def get_cache_file() -> pathlib.Path:
    default = pathlib.Path.home() / ".cache" / "lpt_guarantees_state.json"
    return pathlib.Path(os.environ.get("GUARANTEES_CACHE_FILE", str(default))).expanduser()


def scan_guarantees(target_dir: pathlib.Path, search_dirs: list[pathlib.Path]) -> dict:
    """走査対象を優先順位付きで見て、docs/guarantees.md を持つディレクトリを名前で束ねる。"""
    priority = {str(d.resolve()): idx for idx, d in enumerate(search_dirs)}
    home = pathlib.Path.home()

    # repo_name -> 同名リポの出現一覧（走査元・パス・mtime）
    repos: dict[str, list[dict]] = {}

    for search_dir in search_dirs:
        if not search_dir.is_dir():
            # 走査対象が存在しない場合は黙って読み飛ばす
            continue
        for item in search_dir.iterdir():
            if not item.is_dir() or item.name.startswith("."):
                continue
            # 集約先自身とその親は走査対象から除外する（自分が張った symlink を拾って再帰しない）
            if item.resolve() == target_dir.resolve() or item.resolve() == target_dir.parent.resolve():
                continue
            guarantee_file = item / "docs" / "guarantees.md"
            if guarantee_file.is_file():
                repo_name = item.name
                repos.setdefault(repo_name, []).append(
                    {
                        "search_dir": search_dir,
                        "path": str(guarantee_file),
                        "mtime": guarantee_file.stat().st_mtime,
                    }
                )

    found = {}
    for repo_name, instances in repos.items():
        if len(instances) == 1:
            inst = instances[0]
            found[f"{repo_name}.md"] = {"path": inst["path"], "mtime": inst["mtime"]}
            continue

        # 優先順位（search_dirs の列挙順）でソートし、最上位が接頭辞なしの名前を取る
        instances.sort(key=lambda x: priority.get(str(x["search_dir"].resolve()), len(search_dirs)))
        primary = instances[0]
        found[f"{repo_name}.md"] = {"path": primary["path"], "mtime": primary["mtime"]}

        for inst in instances[1:]:
            search_dir = inst["search_dir"]
            prefix = "home" if search_dir.resolve() == home.resolve() else search_dir.name
            found[f"{prefix}-{repo_name}.md"] = {"path": inst["path"], "mtime": inst["mtime"]}

    return found


def main():
    target_dir = get_target_dir()
    search_dirs = get_search_dirs()
    cache_file = get_cache_file()

    target_dir.mkdir(parents=True, exist_ok=True)

    current_state = scan_guarantees(target_dir, search_dirs)

    old_state = {}
    if cache_file.is_file():
        try:
            with open(cache_file, "r") as f:
                old_state = json.load(f)
        except Exception:
            # キャッシュが壊れていても例外で落とさず、再生成へ進む
            old_state = {}

    has_changed = set(current_state.keys()) != set(old_state.keys()) or any(
        link_name not in old_state or old_state[link_name]["mtime"] != info["mtime"]
        for link_name, info in current_state.items()
    )

    if not has_changed:
        print("[lpt] No changes in guarantees.md files. Skipping symlink regeneration.")
        return

    print("[lpt] Changes detected in guarantees.md. Regenerating symlinks...")

    for link in target_dir.iterdir():
        if link.is_symlink():
            link.unlink()

    for link_name, info in current_state.items():
        src = pathlib.Path(info["path"])
        dst = target_dir / link_name
        try:
            # 相対パスで張る。集約先ごと別の場所へ移しても壊れないようにするため
            rel_src = os.path.relpath(src, dst.parent)
            dst.symlink_to(rel_src)
            print(f"[lpt] Linked: {dst.name} -> {rel_src}")
        except Exception as e:
            print(f"[lpt] Failed to create symlink for {link_name}: {e}")

    cache_file.parent.mkdir(parents=True, exist_ok=True)
    with open(cache_file, "w") as f:
        json.dump(current_state, f, indent=2)


if __name__ == "__main__":
    main()
